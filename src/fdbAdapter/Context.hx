package fdbAdapter;

import adapter.Handles;
import adapter.ProtocolServer;
import protocol.debug.Types;

class Context
{
    public var variableHandles(default, null):Handles<String>;
    public var sourcePath(default, default):String;
    public var breakpoints(default, null):Map<String, Array<Breakpoint>>;
    public var debugger(default, null):IDebugger;
    public var protocol(default, null):ProtocolServer;
    public var debuggerState(default, default):EDebuggerState;

    public function new( protocol:ProtocolServer, debugger:IDebugger) {
        this.protocol = protocol;
        this.debugger = debugger;

        breakpoints = new Map<String, Array<Breakpoint>>();
        variableHandles = new Handles<String>();
    }
}