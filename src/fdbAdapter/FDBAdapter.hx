package fdbAdapter;

import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import fdbAdapter.commands.DebuggerCommand;
import fdbAdapter.commands.fdb.*;
import fdbAdapter.FDBServer.FDBConfig;

typedef AdapterConfig = {
    var fdbConfig : FDBConfig;
}

class FDBAdapter extends adapter.DebugSession
{
    static var config:AdapterConfig;
    public static function setup( config:AdapterConfig )
    {
        FDBAdapter.config = config;
    }

    var breakpointsManager:BreakpointsManager;
    var debugger:IDebugger;
    var sourcePath:String;

    public function new()
    {
        super();
    }

    override function dispatchRequest(request: Request<Dynamic>): Void 
    {
        trace( request );
        super.dispatchRequest(request);
    }

    override function sendResponse(response:protocol.debug.Response<Dynamic>):Void
    {
        trace('SEND RESPONSE: $response' );
        super.sendResponse(response);
    }

    override function initializeRequest(response:InitializeResponse, args:InitializeRequestArguments):Void
    {
        if (config == null)
        {
            response.success = false;
            response.message = "setup with config first";
            this.sendResponse( response );
            return;
        }
        debugger = new FDBServer( config.fdbConfig, this );
        breakpointsManager = new BreakpointsManager(this, debugger);

        debugger.start();
        // this.sendEvent(new InitializedEvent());
		// This debug adapter implements the configurationDoneRequest.
		response.body.supportsConfigurationDoneRequest = true;

		// make VS Code to use 'evaluate' when hovering over source
		response.body.supportsEvaluateForHovers = true;

		// make VS Code to show a 'step back' button
		response.body.supportsStepBack = true;
        trace( 'got initialize request: $response');
        this.sendResponse( response );
    }

    override function launchRequest(response:LaunchResponse, args:LaunchRequestArguments):Void
    {
        var customArgs:{
            var sourcePath:String;
        } = cast args;

        sourcePath = customArgs.sourcePath;
        debugger.queueCommand(new Launch(this, debugger, response, cast args));
    }


    override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments)
    {
        breakpointsManager.setBreakPointsRequest(response, args );
    }

    override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments):Void
    {
        sendResponse(response);
        debugger.queueCommand(new Continue(this,debugger));
    }

    override function threadsRequest(response:ThreadsResponse):Void
    {
        response.body = {
            threads: [
                new ThreadImpl(1, "thread 1")
            ]
        };
        sendResponse(response);
    }

    override function stackTraceRequest(response:StackTraceResponse, args:StackTraceArguments):Void
    {
        debugger.queueCommand( new StackTrace(this, debugger, response, sourcePath));
    }
}
