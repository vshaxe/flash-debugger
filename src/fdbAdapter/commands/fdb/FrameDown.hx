package fdbAdapter.commands.fdb;

class FrameDown extends DebuggerCommand {
   
    public function new(context:Context) {
        super(context);
    }

    override function execute() {
        debugger.send("down");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        trace(lines);
        var line = lines[0];
        switch (context.debuggerState) {
            case EDebuggerState.Stopped(frames, currentFrame):
                context.debuggerState = EDebuggerState.Stopped(frames, currentFrame - 1);
            default:
        }
        setDone();
     }
}