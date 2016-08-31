package fdbAdapter;
import protocol.debug.Types;
import adapter.DebugSession;
import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.child_process.ChildProcess.ChildProcessEvent;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable;
import fdbAdapter.FDBCommand;




typedef AdapterConfig = {
    var fdbPath : String;
}

class FDBAdapter extends adapter.DebugSession
{
    static var config:AdapterConfig;
    public static function setup( config:AdapterConfig )
    {
        FDBAdapter.config = config;
    }

    var proc:ChildProcessObject;
    var buffer:Buffer;
    var commandsQueueHead:FDBCommand;
    var currentCommand:FDBCommand;

    public function new()
    {
        super();
        buffer = new Buffer(0);
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

        proc = ChildProcess.spawn(config.fdbPath, [], {env: {}});
        proc.stdout.on(ReadableEvent.Data,  onData );
        proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {trace("~~~~~~~~~~");});

        queueCommand( new StartFDBCommand(this) );
      
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

    function queueCommand( command:FDBCommand )
    {
        if (currentCommand == null)
        {
            commandsQueueHead = currentCommand = command;
            checkQueue();
        }
        else
        {
            currentCommand.next = command;
            command.prev = currentCommand;
        }
        
    }

    function checkQueue()
    {
        currentCommand.execute(proc);
    }

    function onData( buf:Buffer )
    {
        
        var newLength = buffer.length + buf.length;
        buffer = Buffer.concat([buffer,buf], newLength);
        var string = buffer.toString();
        if (string.substr(-6) == "(fdb) ")
        {
            trace( string );
        }



        //this.sendEvent( new InitializedEvent());
    }
}