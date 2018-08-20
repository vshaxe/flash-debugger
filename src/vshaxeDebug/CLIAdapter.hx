package vshaxeDebug;

import js.Error;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.stream.Readable.ReadableEvent;
import js.node.child_process.ChildProcess as ChildProcessObject;

typedef CLIAdapterConfig = {
	var cmdParams:Array<String>;
	var cmd:String;
	var onPromptGot:Array<String>->Void;
	var onError:Error->String;
	var allOutputReceiver:String->Bool;
	var commandBuilder:ICommandBuilder;
	var parser:IParser;
}

private class DebuggerCommand {
	var cmd:String;
	var resultReceiver:Array<String>->Bool;

	public var done(default, null):Bool;
	public var prev:DebuggerCommand;
	public var next:DebuggerCommand;

	public function new(cmd:String, ?resultReceiver:Array<String>->Bool) {
		this.cmd = cmd;
		this.resultReceiver = resultReceiver;
		this.done = false;
	}

	public function execute(inputHandle:String->Void) {
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
	var onPromptGot:Array<String>->Void;
	var onError:Error->String;
	var allOutputReceiver:String->Bool;
	var proc:ChildProcessObject;
	var buffer:Buffer;
	var currentCommand:DebuggerCommand;
	var queueHead:DebuggerCommand;
	var queueTail:DebuggerCommand;

	public var commandBuilder(default, null):ICommandBuilder;
	public var parser(default, null):IParser;

	public function new(config:CLIAdapterConfig) {
		this.config = config;
		this.onPromptGot = config.onPromptGot;
		this.onError = config.onError;
		this.allOutputReceiver = config.allOutputReceiver;
		this.commandBuilder = config.commandBuilder;
		this.parser = config.parser;
		buffer = new Buffer(0);
	}

	public function start() {
		var env = {};
		for (k in Sys.environment().keys()) {
			Reflect.setField(env, k, Sys.getEnv(k));
		}
		proc = ChildProcess.spawn(config.cmd, config.cmdParams, {env: env});
		proc.stdout.on(ReadableEvent.Data, onData);
		proc.stderr.on(ReadableEvent.Data, function(buf:Buffer) {
			trace(buf.toString());
		});
	}

	public function stop() {
		proc.kill("SIGINT");
	}

	public function queueSend(command:String, ?callback:Array<String>->Bool) {
		var cmd = new DebuggerCommand(command, callback);
		queueCommand(cmd);
	}

	public function queueCommand(command:DebuggerCommand) {
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
		trace('send to debugger cli: $command\n');
		try {
			proc.stdin.write('$command\n');
		} catch (e:Error) {
			throw onError(e);
		}
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
		if (currentCommand.done) {
			removeCurrentCommand();
		}
	}

	function removeCurrentCommand() {
		currentCommand = null;
		checkQueue();
	}

	function removeCommand(command:DebuggerCommand) {
		if (command == queueHead) {
			queueHead = command.next;
		}
		if (command == queueTail) {
			queueTail = command.prev;
		}
		if (command.prev != null) {
			command.prev.next = command.next;
		}
		if (command.next != null) {
			command.next.prev = command.prev;
		}
	}

	function onData(buf:Buffer) {
		var newLength = buffer.length + buf.length;
		buffer = Buffer.concat([buffer, buf], newLength);
		var rawInput:String = buffer.toString();
		if (parser.isPromptMatched(rawInput)) {
			var lines = parser.getLinesExceptPrompt(rawInput);
			lines.pop();
			buffer = new Buffer(0);
			if (currentCommand != null) {
				currentCommand.processResult(lines);
				if (currentCommand.done) {
					removeCurrentCommand();
				}
			}
			onPromptGot(lines);
		} else {
			if (allOutputReceiver(rawInput)) {
				buffer = new Buffer(0);
			}
		}
	}
}
