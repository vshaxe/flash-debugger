package fdbAdapter;

import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable;
import fdbAdapter.commands.DebuggerCommand;

typedef FDBConfig = {
    var fdbCmdParams : Array<String>;
    var fdbCmd : String;
}

class FDBServer implements IDebugger {

    var config:FDBConfig;
    var processDebuggerOutput:Array<String> -> Void;
    var proc:ChildProcessObject;
    var buffer:Buffer;

    var currentCommand:DebuggerCommand;

    var queueHead:DebuggerCommand;
    var queueTail:DebuggerCommand;

    public function new(config:FDBConfig, processDebuggerOutput:Array<String> -> Void) {
        this.config = config;
        this.processDebuggerOutput = processDebuggerOutput;
        buffer = new Buffer(0);
    }

    public function start() {
        proc = ChildProcess.spawn(config.fdbCmd, config.fdbCmdParams, {env: {}});
        proc.stdout.on(ReadableEvent.Data,  onData );
        proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {trace(buf.toString());});
    }

    public function queueCommand(command:DebuggerCommand) {
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
    
    public function send(command:String) {
        proc.stdin.write('$command\n');
    }
    
    function checkQueue() {
        if ((currentCommand == null) && (queueHead != null)) {
            currentCommand = queueHead;
            queueHead = currentCommand.next;
            executeCurrentCommand();
        }
    }

    function executeCurrentCommand() {        
        currentCommand.execute();
        if (currentCommand.done)
            removeCurrentCommand();
    }

    function removeCurrentCommand() {
        currentCommand = null;
        checkQueue();
    }

    function removeCommand(command:DebuggerCommand) {
        if (command == queueHead)
            queueHead = command.next;
        if (command == queueTail)
            queueTail = command.prev;
        if (command.prev != null)
            command.prev.next = command.next;
        if (command.next != null)
            command.next.prev = command.prev;
    }

    function onData(buf:Buffer) {
        var newLength = buffer.length + buf.length;
        buffer = Buffer.concat([buffer,buf], newLength);
        var string = buffer.toString();
        if (string.substr(-6) == "(fdb) ") {
            var fdbOutput = string.substring(0, string.length - 6 );
            var lines = fdbOutput.split("\r\n");
            lines.pop();
            buffer = new Buffer(0);
            if (currentCommand != null) {
                currentCommand.processDebuggerOutput(lines);
                if (currentCommand.done)
                    removeCurrentCommand();
            }
            processDebuggerOutput( lines );
        }
    }
}
