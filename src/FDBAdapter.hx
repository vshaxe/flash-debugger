package;

import fdbAdapter.commands.*;
import vshaxeDebug.Context;
import vshaxeDebug.IDebugger;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.EScope;
import vshaxeDebug.CommandsBatch;
import vshaxeDebug.EDebuggerState;
import vshaxeDebug.BreakpointsManager;
import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import js.node.Fs;
import haxe.ds.Option;

class FDBAdapter extends adapter.DebugSession {

    var breakpointsManager:BreakpointsManager;
    var debugger:IDebugger;
    var context:Context;

    public function new() {
        super();
    }

    override function dispatchRequest(request:Request<Dynamic>) {
        trace( request );
        super.dispatchRequest(request);
    }

    override function sendResponse(response:protocol.debug.Response<Dynamic>) {
        trace('SEND RESPONSE: $response' );
        super.sendResponse(response);
    }

    override function initializeRequest(response:InitializeResponse, args:InitializeRequestArguments) {
        var scriptPath = js.Node.__dirname;
        var cliAdapterConfig = {
            cmd:"java",
            cmdParams:["-Duser.language=en", "-jar", '$scriptPath/../fdb/fdb.jar'],
            prompt:"(fdb) ",
            onPromptGot:onPromptGot,
            allOutputReceiver:allOutputReceiver
        };

        debugger = new CLIAdapter(cliAdapterConfig);
        context = new Context(this, debugger);
        breakpointsManager = new BreakpointsManager(context, getBreakpointsCmdFactory());

        debugger.start();

        response.body.supportsConfigurationDoneRequest = true;
        response.body.supportsEvaluateForHovers = true;
        response.body.supportsStepBack = false;
        context.sendToOutput("fdb initializing");
        this.sendResponse( response );
    }

    override function launchRequest(response:LaunchResponse, args:LaunchRequestArguments) {
        
        debugger.queueCommand(new Launch(context, response, cast args));
        debugger.queueCommand(new CacheSourcePaths(context));
    }

    override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        breakpointsManager.setBreakPointsRequest(response, args );
    }

    override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments) {
        sendResponse(response);
        debugger.queueCommand(new Continue(context));
    }

    override function threadsRequest(response:ThreadsResponse) {
        response.body = {
            threads: [
                new ThreadImpl(1, "thread 1")
            ]
        };
        sendResponse(response);
    }

    override function stackTraceRequest(response:StackTraceResponse, args:StackTraceArguments) {
        debugger.queueCommand( new StackTrace(context, response));
    }

    override function scopesRequest(response:ScopesResponse, args:ScopesArguments) {
        var frameId:Int = args.frameId;
        var scopes:Array<Scope> = [
            new ScopeImpl("Local", context.variableHandles.create('local_$frameId'), false),
            new ScopeImpl("Closure", context.variableHandles.create('closure_$frameId'), false),
            new ScopeImpl("Global", context.variableHandles.create('global_$frameId'), true)
        ];

        response.body = {
            scopes: cast scopes
        };
        this.sendResponse(response);
    }

    override function variablesRequest(response:VariablesResponse, args:VariablesArguments) {
        var id = args.variablesReference;
        var handleId:String = context.variableHandles.get(id);
        var scope:EScope = getScopeOfHandle(handleId);
        var framesDiff:Int = getFramesDiff(scope);
        var variablesResult:Array<protocol.debug.Variable> = [];

        var callback = function() {
            response.body = {
                variables : variablesResult
            };
            sendResponse(response);
        };

        if (framesDiff != 0) {
            for (i in 0...Math.floor(Math.abs(framesDiff))) {   
                if (framesDiff < 0)
                    debugger.queueCommand(new FrameUp(context));
                else
                    debugger.queueCommand(new FrameDown(context));
            }
        }

        var batch = new CommandsBatch(context.debugger, callback);
        switch (scope) {
            case Locals(frameId, _):
                batch.add(new Variables(context, Locals(frameId, FunctionArguments), variablesResult));
                batch.add(new Variables(context, Locals(frameId, LocalVariables), variablesResult));
            case _:
                batch.add(new Variables(context, scope, variablesResult));
        }
    }

    override function evaluateRequest(response:EvaluateResponse, args:EvaluateArguments) {
        trace( 'evaluate: $args');
        debugger.queueCommand(new Evaluate(context, response, args));
    }

    override function stepInRequest(response:StepInResponse, args:StepInArguments) {
        debugger.queueCommand(new StepInCommand(context, response));
    }

    override function stepOutRequest(response:StepOutResponse, args:StepOutArguments) {
        debugger.queueCommand(new StepOutCommand(context, response));
    }

    override function nextRequest(response:NextResponse, args:NextArguments) {
        debugger.queueCommand(new NextCommand(context, response));
    }

    override function continueRequest(response:ContinueResponse, args:ContinueArguments) {
        debugger.queueCommand(new Continue(context));
        response.body = {
            allThreadsContinued : true
        }
        sendResponse( response );
    }

    override function pauseRequest(response:PauseResponse, args:PauseArguments) {
        debugger.queueCommand(new Pause(context, response));
    }

    override function disconnectRequest(response:DisconnectResponse, args:DisconnectArguments) {
        debugger.stop();
        sendResponse(response);
    }

    function getBreakpointsCmdFactory():BreakpointsCommandsFactory {
        return {
            stopForBreakpointsSetting : fdbAdapter.commands.StopForBreakpointsSetting.new,
            continueAfterBreakpointsSet : fdbAdapter.commands.ContinueAfterBreakpointsSet.new,
            setBreakpoint : fdbAdapter.commands.SetBreakpoint.new,
            removeBreakpoint : fdbAdapter.commands.RemoveBreakpoint.new
        };
    }

    function onPromptGot(lines:Array<String>) {
        switch (context.debuggerState) {
            case EDebuggerState.WaitingGreeting:
                if (greetingMatched(lines)) {
                    context.onEvent(GreetingReceived);
                }
                else
                    trace( 'Start FAILED: [ $lines ]');

            case EDebuggerState.Running:                
                if (onBreakpoint(lines)) {
                    context.onEvent(Stop(StopReason.breakpoint));
                }
                else if (onFault(lines)) {
                    context.onEvent(Stop(StopReason.exception));
                }
            case _:
         
        }
    }

    function allOutputReceiver(string:String):Bool {
        var procceed:Bool = false;
        var exitR = ~/\[UnloadSWF\]/;        
        if (exitR.match(string)) {
            var exitedEvent:ExitedEvent = {type:MessageType.event, event:"exited", seq:0, body : { exitCode:0}}; 
            sendEvent(exitedEvent);
            debugger.stop();
            return true;
        }

        switch (context.debuggerState) {
            case EDebuggerState.Running:
                var lines = string.split("\r\n");
                var traceR = ~/\[trace\](.*)/;
                for (line in lines)
                    if (traceR.match(line)) {
                        context.sendToOutput(line);
                        procceed = true;
                    }
            default:
        }
        return procceed;
    }

    function greetingMatched(lines:Array<String>):Bool {
        var firstLine = lines[0];
        if (firstLine == null)
            return false;

        return (firstLine.substr(0,5) == "Adobe");
    }

    function onBreakpoint(lines:Array<String>):Bool {
        for (line in lines) {
            var r = ~/Breakpoint ([0-9]+),(.*) (.+).hx:([0-9]+)/;
            if (r.match(line))
                return true;
        }
        return false;
    }

    function onFault(lines:Array<String>):Bool {        
        for (line in lines) {
            var r = ~/^\[Fault\].*/;
            if (r.match(line))
                return true;
        }
        return false;
    }

    function getScopeOfHandle(handleId:String):EScope {
        var parts:Array<String> = handleId.split("_");
        var prefix = parts[0];

        return switch (prefix) {
            case "local":
                Locals(Std.parseInt(parts[1]), ScopeLocalsType.NotSpecified);
            case "global":
                Global(Std.parseInt(parts[1]));
            case "closure":
                Closure(Std.parseInt(parts[1]));
            case "object":
                var objectId:Int = Std.parseInt(parts[1]);
                var objectName:String = context.knownObjects.get(objectId); 
                ObjectDetails(objectId, objectName);
            case _:
                throw "could not recognize";
        }
    }

    function getFramesDiff(scope:EScope):Int {
        var frameId:Option<Int> = switch (scope) {
            case Locals(frameId, _):
                Some(frameId);
            case Global(frameId):
                Some(frameId);
            case Closure(frameId):
                Some(frameId);
            default:
                None;
        }

        var currentFrame = switch ( context.debuggerState ) {
            case Stopped(frames, currentFrame):
                Some(currentFrame);
            default:
                None;
        }

        return switch [frameId, currentFrame] {
            case [ Some( requestedFrame ), Some( currentFrame ) ]:
                currentFrame - requestedFrame;
            default:
                0;
        }
    }

    static function main() {
        setupTrace();
        DebugSession.run( FDBAdapter );
    }

    static function setupTrace() {
        logPath = js.Node.__dirname + "/../fdb_log.txt";
        Fs.writeFile(logPath, "", "utf8", function(e){});
        haxe.Log.trace = function(v, ?i) {
            var r = [Std.string(v)];
            Log({type: "INFO", message: r.join(" ")});
        }
    }

    static function Log(input:{type:String, message:String}) {
        Fs.appendFile(logPath, haxe.Json.stringify(input) + "\n", 'utf8', function(e){ });
    }

    static var logPath:String;
}
