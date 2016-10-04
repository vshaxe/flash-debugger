package fdbAdapter;

import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import protocol.debug.Types.StopReason;
import protocol.debug.Types.MessageType;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;
import adapter.DebugSession.OutputEvent as OutputEventImpl;

import fdbAdapter.commands.fdb.*;
import fdbAdapter.types.VarRequestType;
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
        breakpointsManager = new BreakpointsManager(context);

        context.debuggerState = WaitingGreeting;
        debugger.start();

        response.body.supportsConfigurationDoneRequest = true;
        response.body.supportsEvaluateForHovers = false;
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
        var varId:String = context.variableHandles.get(id);
        var requestType:VarRequestType = getVariablesRequestType(varId);
        var framesDiff:Int = getFramesDiff(requestType);

        if (framesDiff != 0) {
            for (i in 0...Math.floor(Math.abs(framesDiff))) {   
                if (framesDiff < 0)
                    debugger.queueCommand(new FrameUp(context));
                else
                    debugger.queueCommand(new FrameDown(context));
            }
        }
        debugger.queueCommand(new Variables(context, response, requestType));
    }

    override function evaluateRequest(response:EvaluateResponse, args:EvaluateArguments) {
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

    function onPromptGot(lines:Array<String>) {
        switch (context.debuggerState) {
            case EDebuggerState.WaitingGreeting:
                if (greetingMatched(lines)) {
                    context.debuggerState = EDebuggerState.Configuring;
                    sendEvent( new InitializedEvent());
                }
                else
                    trace( 'Start FAILED: [ $lines ]');

            case EDebuggerState.Running:
                if (breakpointMet(lines)) {
                    context.enterStoppedState(StopReason.breakpoint);
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

    function breakpointMet(lines:Array<String>):Bool {
        for (line in lines) {
            var r = ~/Breakpoint ([0-9]+),(.*) (.+).hx:([0-9]+)/;
            if (r.match(line))
                return true;
        }
        return false;
    }

    function traceMatched(lines:Array<String>):Bool {
        return true;
    }

    function getVariablesRequestType(varId:String):VarRequestType {
        var parts:Array<String> = varId.split("_");
        var requestType = parts[0];
        return switch (requestType) {
            case "local":
                Locals(Std.parseInt(parts[1]));
            case "global":
                Global(Std.parseInt(parts[1]));
            case "closure":
                Closure(Std.parseInt(parts[1]));
            case "object":
                ObjectDetails(parts[1]);
            case _:
                throw "unrecognized";
        }
    }

    function getFramesDiff(requestType:VarRequestType):Int {
        var frameId:Option<Int> = switch (requestType) {
            case Locals(frameId):
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
}
