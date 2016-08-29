package fdbAdapter;
import protocol.debug.Types;
import adapter.DebugSession;

class FDBAdapter extends adapter.DebugSession
{
    public function new()
    {
        super();
    }

    override function initializeRequest(response:InitializeResponse, args:InitializeRequestArguments):Void
    {
        
        this.sendEvent(new InitializedEvent());
		// This debug adapter implements the configurationDoneRequest.
		response.body.supportsConfigurationDoneRequest = true;

		// make VS Code to use 'evaluate' when hovering over source
		response.body.supportsEvaluateForHovers = true;

		// make VS Code to show a 'step back' button
		response.body.supportsStepBack = true;
        trace( 'got initialize request: $response');
        this.sendResponse( response );
    }
}