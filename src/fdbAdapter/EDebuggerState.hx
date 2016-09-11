package fdbAdapter;

import protocol.debug.Types;

enum EDebuggerState
{
    WaitingGreeting;
    Configuring;
    Running;
    Stopped(frames:Array<StackFrame>, currentFrame:Int);
}