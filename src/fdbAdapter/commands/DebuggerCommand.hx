package fdbAdapter.commands;
import adapter.ProtocolServer;
import js.node.ChildProcess;

interface IQueueItem<T>
{
    var prev:T;
    var next:T;
    var done(get,set):Bool;
}

class DebuggerCommand implements IQueueItem<DebuggerCommand>
{
    public var prev:DebuggerCommand;
    public var next:DebuggerCommand;
    public var done(get,set):Bool;

    public var callback(never,set):Void->Void;

    var command:String;
    var protocol:ProtocolServer;
    var debugger:IDebugger;
    var _callback:Void->Void = function() {};
    var _done = false;

    public function new(protocol:ProtocolServer, debugger:IDebugger) 
    {
        this.protocol  = protocol;
        this.debugger = debugger; 
    }

    public function execute():Void {}
    public function processDebuggerOutput(lines:Array<String>):Void {}

    function get_done():Bool
        return _done;

    function set_done(val:Bool):Bool
    {
        if (val)
            _callback();
        return _done = val;
    }

    function set_callback(callback:Void->Void):Void->Void
    {
        _callback = callback;
        return _callback;
    }
}
