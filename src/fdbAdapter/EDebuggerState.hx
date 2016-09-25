package fdbAdapter;

import protocol.debug.Types.StackFrame;

enum EDebuggerState {
    WaitingGreeting;
    Configuring;
    Running;
    Stopped(frames:Array<StackFrame>, currentFrame:Int);
}
