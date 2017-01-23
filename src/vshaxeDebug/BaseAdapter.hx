package vshaxeDebug;

import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import vshaxeDebug.Types;
import js.node.Fs;

class BaseAdapter extends adapter.DebugSession {

    var debugger:IDebugger;
    var context:Context;
    var cmd:ICommandBuilder;
   
    public function new() {
        super();
    }

    function initializeContext(program:String) {
        throw "abstract method: implement me";
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
        var customArgs:ExtLaunchRequestArguments = cast args;
        initializeContext(customArgs.program);   
        if ((customArgs.receiveAdapterOutput != null) && 
            (customArgs.receiveAdapterOutput)) {
            redirectTraceToDebugConsole(context);
        }
        var command = new vshaxeDebug.commands.Launch(context, response, customArgs);
        command.execute();
    }

    override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        var command = new vshaxeDebug.commands.SetBreakpoints(context, response, args);
        command.execute();
    }

    override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments) {
        debugger.queueSend(cmd.continueCommand());
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
        var command = new vshaxeDebug.commands.Variables(context, response, args);
        command.execute();
    }

    override function evaluateRequest(response:EvaluateResponse, args:EvaluateArguments) {
        var command = new vshaxeDebug.commands.Evaluate(context, response, args);
        command.execute();
    }

    override function stepInRequest(response:StepInResponse, args:StepInArguments) {
        stepRequest(cmd.stepIn(), response);
    }

    override function stepOutRequest(response:StepOutResponse, args:StepOutArguments) {
        stepRequest(cmd.stepOut(), response);
    }

    override function nextRequest(response:NextResponse, args:NextArguments) {
        stepRequest(cmd.next(), cast response);
    }

    function stepRequest<T>(cmd:String, response:protocol.debug.Response<T>) {
        debugger.queueSend(cmd, function(_):Bool {
            sendResponse(response);
            sendEvent(new StoppedEvent("step", 1));
            return true;
        });
    }

    override function continueRequest(response:ContinueResponse, args:ContinueArguments) {
        debugger.queueSend(cmd.continueCommand());
        sendResponse(response);
        context.onEvent(Continue);
    }

    override function pauseRequest(response:PauseResponse, args:PauseArguments) {
        debugger.queueSend(cmd.pause(), function(_):Bool {
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

    function redirectTraceToDebugConsole(context:Context) {
        haxe.Log.trace = function(v, ?i) {
            context.sendToOutput('DebugAdapter: $v', OutputEventCategory.stdout);
        }
    }
}
