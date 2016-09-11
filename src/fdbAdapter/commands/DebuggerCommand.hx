package fdbAdapter.commands;
import adapter.ProtocolServer;
import js.node.ChildProcess;

interface IQueueItem<T> {
    var prev:T;
    var next:T;
    var done(get,never):Bool;
}

class DebuggerCommand implements IQueueItem<DebuggerCommand> {
    public var prev:DebuggerCommand;
    public var next:DebuggerCommand;
    public var done(get, never):Bool;

    public var callback(never,set):Void->Void;

    var command:String;
    var context:Context;
    var protocol:ProtocolServer;
    var debugger:IDebugger;
    var _callback:Void -> Void = function() {};
    var _done = false;

    public function new(context:Context) {
        this.context = context;
        this.protocol = context.protocol;
        this.debugger = context.debugger; 
    }

    public function execute() {}
    public function processDebuggerOutput(lines:Array<String>) {}
    
    function setDone() {
        _callback();
        _done = true;
    }

    function get_done():Bool
        return _done;

    function set_callback(callback:Void -> Void):Void -> Void {
        _callback = callback;
        return _callback;
    }
}
