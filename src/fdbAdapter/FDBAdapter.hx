package fdbAdapter;
import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;
import adapter.DebugSession.Thread as ThreadImpl;
import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable;
import fdbAdapter.FDBCommand;




typedef AdapterConfig = {
    var fdbCmdParams : Array<String>;
    var fdbCmd : String;
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
    var queueHead:FDBCommand;
    var queueTail:FDBCommand;
    var currentCommand:FDBCommand;
    var breakpointsManager:BreakpointsManager;

    public function new()
    {
        super();
        buffer = new Buffer(0);
        breakpointsManager = new BreakpointsManager(this);
    }

    public function queueCommand( command:FDBCommand )
    {
        // add to the queue
        if (queueHead == null) {
            queueHead = queueTail = command;
        } else {
            queueTail.next = command;
            command.prev = queueTail;
            queueTail = command;
        }
        checkQueue();
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

        proc = ChildProcess.spawn(config.fdbCmd, config.fdbCmdParams, {env: {}});
        proc.stdout.on(ReadableEvent.Data,  onData );
        proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {trace(buf.toString());});

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

    override function launchRequest(response:LaunchResponse, args:LaunchRequestArguments):Void
    {
        queueCommand( new LaunchCommand(this, response, cast args) );
    }


    override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments)
    {
        breakpointsManager.setBreakPointsRequest(response, args );
    }

    override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments):Void
    {
        sendResponse(response);
        queueCommand( new ContinueCommand(this));
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

    function checkQueue()
    {
        if ((currentCommand == null) && (queueHead != null)) 
        {
            currentCommand = queueHead;
            queueHead = currentCommand.next;
            executeCurrentCommand();
        }
    }

    function executeCurrentCommand()
    {        
        currentCommand.execute(proc);
        if (currentCommand.done)
            removeCurrentCommand();
    }

    function removeCurrentCommand()
    {
        currentCommand = null;
        checkQueue();
    }

    function removeCommand(command:FDBCommand):Void
    {
        if (command == queueHead)
            queueHead = command.next;
        if (command == queueTail)
            queueTail = command.prev;
        if (command.prev != null)
            command.prev.next = command.next;
        if (command.next != null)
            command.next.prev = command.prev;
    }

    function onData( buf:Buffer )
    {
            
        var newLength = buffer.length + buf.length;
        buffer = Buffer.concat([buffer,buf], newLength);
        var string = buffer.toString();
        if (string.substr(-6) == "(fdb) ")
        {
            var fdbOutput = string.substring(0, string.length - 6 );
            var lines = fdbOutput.split("\r\n");
            lines.pop();
            buffer = new Buffer(0);
            if (currentCommand != null)
            {
                currentCommand.processFDBOutput(proc, lines );
                if (currentCommand.done)
                    removeCurrentCommand();
            }            
            else 
            {
                globalStateProcess( lines );
            }
        }
    }

    function globalStateProcess(lines:Array<String>)
    {
        trace('globalStateProcess: $lines');
        for (line in lines)
        {
            //Breakpoint 1, GameRound() at GameRound.hx:18
            var r = ~/Breakpoint ([0-9]+), (.*) at ([0-9A-Za-z\.]+).hx:([0-9]+)/;
            if (r.match(line))
            {
                this.sendEvent(new StoppedEventImpl("breakpoint", 1));
            }
        }

    }

}