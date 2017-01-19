package vshaxeDebug;

import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable.ReadableEvent;
import js.node.child_process.ChildProcess as ChildProcessObject;

typedef CLIAdapterConfig = {
    var cmdParams:Array<String>;
    var cmd:String;
    var prompt:String;
    var onPromptGot:Array<String> -> Void;
    var allOutputReceiver:String -> Bool;
    var translator:ITranslator;
}

private class DebuggerCommand {

    var cmd:String;
    var resultReceiver:Array<String> -> Bool;

    public var done(default, null):Bool;
    public var prev:DebuggerCommand;
    public var next:DebuggerCommand;

    public function new(cmd:String, ?resultReceiver:Array<String> -> Bool) {
        this.cmd = cmd;
        this.resultReceiver = resultReceiver;
        this.done = false;
    }

    public function execute(inputHandle:String -> Void) {
        inputHandle(cmd);
        if (resultReceiver == null) {
            setDone();
        }
    }

    public function processResult(lines:Array<String>) {
        if (resultReceiver(lines)) {
            setDone();
        }
    }

    function setDone() {
        done = true;
    }
}

class CLIAdapter implements IDebugger {

    var config:CLIAdapterConfig;
    var onPromptGot:Array<String> -> Void;
    var allOutputReceiver:String -> Bool;
    var proc:ChildProcessObject;
    var buffer:Buffer;

    var currentCommand:DebuggerCommand;

    var queueHead:DebuggerCommand;
    var queueTail:DebuggerCommand;

    public var translator(default, null):ITranslator;

    public function new(config:CLIAdapterConfig) {
        this.config = config;
        this.onPromptGot = config.onPromptGot;
        this.allOutputReceiver = config.allOutputReceiver;
        this.translator = config.translator;
        buffer = new Buffer(0);
    }

    public function start() {
        proc = ChildProcess.spawn(config.cmd, config.cmdParams, {env: {}});
        proc.stdout.on(ReadableEvent.Data,  onData );
        proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {trace(buf.toString());});
    }

    public function stop() {
        proc.kill("SIGINT");
    }

    public function queueSend(command:String, ?callback:Array<String> -> Bool) {
        var cmd = new DebuggerCommand(command, callback);
        queueCommand(cmd);
    }

    public function queueCommand(command:DebuggerCommand) {
        // add to the queue
        if (queueHead == null) {
            queueHead = queueTail = command;
        } 
        else {
            queueTail.next = command;
            command.prev = queueTail;
            queueTail = command;
        }
        checkQueue();
    }
    
    public function send(command:String) {
        trace('send to debugger cli: $command\n');
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
        currentCommand.execute(this.send);
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
        var prompt = config.prompt;
        var promptLength = config.prompt.length;
        if (string.substr(-promptLength) == config.prompt) {
            var fdbOutput = string.substring(0, string.length - promptLength );
            var lines = fdbOutput.split("\r\n");
            lines.pop();
            buffer = new Buffer(0);
            if (currentCommand != null) {
                currentCommand.processResult(lines);
                if (currentCommand.done)
                    removeCurrentCommand();
            }
            onPromptGot(lines);
        }
        else {
            var lines = string.split("\r\n");
            if (allOutputReceiver(string))
                buffer = new Buffer(0);
        }
    }
}
