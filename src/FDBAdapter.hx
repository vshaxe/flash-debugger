package;

import fdbAdapter.Translator;
import vshaxeDebug.ITranslator;
import vshaxeDebug.Context;
import vshaxeDebug.IDebugger;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.EDebuggerState;
import vshaxeDebug.Types;
import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import js.node.Fs;

class FDBAdapter extends adapter.DebugSession {

    var debugger:IDebugger;
    var context:Context;
    var t:ITranslator;
   
    public function new() {
        super();
    }

    override function dispatchRequest(request:Request<Dynamic>) {
        trace( haxe.Json.stringify(request) );
        super.dispatchRequest(request);
    }

    override function sendResponse(response:protocol.debug.Response<Dynamic>) {
        trace('sendResponse: $response' );
        super.sendResponse(response);
    }

    override function initializeRequest(response:InitializeResponse, args:InitializeRequestArguments) {
        response.body.supportsConfigurationDoneRequest = true;
        response.body.supportsEvaluateForHovers = true;
        response.body.supportsStepBack = false;
        this.sendResponse( response );
    }

    override function launchRequest(response:LaunchResponse, args:LaunchRequestArguments) {
        var scriptPath = js.Node.__dirname;
        t = new Translator();
        var cliAdapterConfig = {
            cmd:"java",
            cmdParams:["-Duser.language=en", "-jar", '$scriptPath/../fdb/fdb.jar'],
            prompt:"(fdb) ",
            onPromptGot:onPromptGot,
            allOutputReceiver:allOutputReceiver,
            translator : t
        };

        debugger = new CLIAdapter(cliAdapterConfig);
        debugger.start();
        context = new Context(this, debugger);

        var customArgs:ExtLaunchRequestArguments = cast args;
        if ((customArgs.receiveAdapterOutput != null) && 
            (customArgs.receiveAdapterOutput)) {
            redirectTraceToDebugConsole(context);
        }
        var cmd = new vshaxeDebug.commands.Launch(context, response, customArgs);
        cmd.execute();
    }

    override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        var cmd = new vshaxeDebug.commands.SetBreakpoints(context, response, args);
        cmd.execute();
    }

    override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments) {
        debugger.queueSend(t.cmdContinue());
        context.onEvent(Continue);
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
        var cmd = new vshaxeDebug.commands.StackTrace(context, response, args);
        cmd.execute();
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
        var cmd = new vshaxeDebug.commands.Variables(context, response, args);
        cmd.execute();
    }

    override function evaluateRequest(response:EvaluateResponse, args:EvaluateArguments) {
        var cmd = new vshaxeDebug.commands.Evaluate(context, response, args);
        cmd.execute();
    }

    override function stepInRequest(response:StepInResponse, args:StepInArguments) {
        stepRequest(t.cmdStepIn(), response);
    }

    override function stepOutRequest(response:StepOutResponse, args:StepOutArguments) {
        stepRequest(t.cmdStepOut(), response);
    }

    override function nextRequest(response:NextResponse, args:NextArguments) {
        stepRequest(t.cmdNext(), cast response);
    }

    function stepRequest<T>(cmd:String, response:protocol.debug.Response<T>) {
        debugger.queueSend(cmd, function(_):Bool {
            sendResponse(response);
            sendEvent(new StoppedEvent("step", 1));
            return true;
        });
    }

    override function continueRequest(response:ContinueResponse, args:ContinueArguments) {
        debugger.queueSend(t.cmdContinue());
        sendResponse(response);
        context.onEvent(Continue);
    }

    override function pauseRequest(response:PauseResponse, args:PauseArguments) {
        debugger.queueSend(t.cmdPause(), function(_):Bool {
            sendResponse(response);
            context.onEvent(Stop(StopReason.pause));
            return true;
        });
    }

    override function disconnectRequest(response:DisconnectResponse, args:DisconnectArguments) {
        debugger.stop();
        sendResponse(response);
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
                if (breakpointMatched(lines)) {
                    context.onEvent(Stop(StopReason.breakpoint));
                }
                else if (faultMatched(lines)) {
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
                for (line in lines) {
                    if (traceR.match(line)) {
                        context.sendToOutput(line);
                        procceed = true;
                    }
                }
            default:
        }
        return procceed;
    }

    function greetingMatched(lines:Array<String>):Bool {
        var firstLine = lines[0];
        return (firstLine != null) ? (firstLine.substr(0, 5) == "Adobe") : false;
    }

    function breakpointMatched(lines:Array<String>):Bool {
        for (line in lines) {
            var r = ~/Breakpoint ([0-9]+),(.*) (.+).hx:([0-9]+)/;
            if (r.match(line)) {
                return true;
            }
        }
        return false;
    }

    function faultMatched(lines:Array<String>):Bool {        
        for (line in lines) {
            var r = ~/^\[Fault\].*/;
            if (r.match(line)) {
                return true;
            }
        }
        return false;
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

    static function redirectTraceToDebugConsole(context:Context) {
        haxe.Log.trace = function(v, ?i) {
            context.sendToOutput('FDB log: $v', OutputEventCategory.stdout);
        }
    }

    static function Log(input:{type:String, message:String}) {
        Fs.appendFile(logPath, haxe.Json.stringify(input) + "\n", 'utf8', function(e){ });
    }

    static var logPath:String;
}
