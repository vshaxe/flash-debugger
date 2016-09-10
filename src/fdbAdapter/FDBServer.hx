package fdbAdapter;

import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable;
import adapter.ProtocolServer;
import fdbAdapter.commands.DebuggerCommand;
import fdbAdapter.commands.fdb.Start;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;

typedef FDBConfig = {
    var fdbCmdParams : Array<String>;
    var fdbCmd : String;
}

class FDBServer implements IDebugger
{
    var protocol:ProtocolServer;
    var proc:ChildProcessObject;
    var buffer:Buffer;
    var queueHead:DebuggerCommand;
    var queueTail:DebuggerCommand;
    var currentCommand:DebuggerCommand;
    var config:FDBConfig;
    
    public function new(config:FDBConfig, protocol:ProtocolServer)
    {
        this.config = config;
        this.protocol = protocol;
        buffer = new Buffer(0);
    }

    public function start()
    {
        proc = ChildProcess.spawn(config.fdbCmd, config.fdbCmdParams, {env: {}});
        proc.stdout.on(ReadableEvent.Data,  onData );
        proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {trace(buf.toString());});

        queueCommand( new Start(protocol, this) );
    }

    public function queueCommand(command:DebuggerCommand)
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
    
    public function send(command:String):Void
    {
        proc.stdin.write('$command\n');
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
        currentCommand.execute();
        if (currentCommand.done)
            removeCurrentCommand();
    }

    function removeCurrentCommand()
    {
        currentCommand = null;
        checkQueue();
    }

    function removeCommand(command:DebuggerCommand):Void
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
                currentCommand.processDebuggerOutput(lines);
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
                protocol.sendEvent(new StoppedEventImpl("breakpoint", 1));
            }
        }

    }
}

