package vshaxeDebug;
import adapter.ProtocolServer;

interface IQueueItem<T> {
    var prev:T;
    var next:T;
    var done(get, never):Bool;
}

class DebuggerCommand implements IQueueItem<DebuggerCommand> {
    
    public var prev:DebuggerCommand;
    public var next:DebuggerCommand;

    @:isVar
    public var done(get, null):Bool;
    @:isVar
    public var callback(null, set):Void -> Void;

    var command:String;
    var context:Context;
    var protocol:ProtocolServer;
    var debugger:IDebugger;

    public function new(context:Context) {
        this.context = context;
        this.protocol = context.protocol;
        this.debugger = context.debugger; 
    }

    public function execute() {}
    public function processDebuggerOutput(lines:Array<String>) {}
    
    function setDone() {
        if (callback != null)
            callback();
        done = true;
    }

    function get_done():Bool
        return done;

    function set_callback(callback:Void -> Void):Void -> Void {
        this.callback = callback;
        return callback;
    }
}
