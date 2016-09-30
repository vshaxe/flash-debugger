package fdbAdapter;

import adapter.Handles;
import adapter.ProtocolServer;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;
import protocol.debug.Types;

class Context {
    
    public var variableHandles(default, null):Handles<String>;
    public var sourcePath(default, default):String;
    public var fileNameToFullPathDict(default, default):Map<String, String>;
    public var breakpoints(default, null):Map<String, Array<Breakpoint>>;
    public var debugger(default, null):IDebugger;
    public var protocol(default, null):ProtocolServer;
    public var debuggerState(default, default):EDebuggerState;

    public function new( protocol:ProtocolServer, debugger:IDebugger) {
        this.protocol = protocol;
        this.debugger = debugger;

        breakpoints = new Map<String, Array<Breakpoint>>();
        fileNameToFullPathDict = new Map<String, String>();
        variableHandles = new Handles<String>();
    }

    public function enterStoppedState(reason:String) {
        debuggerState = EDebuggerState.Stopped([], 0);
        protocol.sendEvent(new StoppedEventImpl(reason, 1));
    }
}
