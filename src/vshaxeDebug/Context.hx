package vshaxeDebug;

import adapter.Handles;
import adapter.ProtocolServer;
import protocol.debug.Types.StopReason;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;
import adapter.DebugSession.OutputEvent as OutputEventImpl;
import protocol.debug.Types;

class Context {
    
    public var variableHandles(default, null):Handles<String>;
    public var knownObjects(default, null):Map<Int,String>;
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
        knownObjects = new Map<Int,String>();
    }

    public function enterStoppedState(reason:StopReason) {
        switch (debuggerState) {
            case EDebuggerState.Running:
                debuggerState = EDebuggerState.Stopped([], 0);
            default:
        }
        protocol.sendEvent(new StoppedEventImpl(reason, 1));
    }

    public function sendToOutput(output:String, category:OutputEventCategory = OutputEventCategory.console) {
        protocol.sendEvent(new OutputEventImpl(output + "\n", category));
    }
}
