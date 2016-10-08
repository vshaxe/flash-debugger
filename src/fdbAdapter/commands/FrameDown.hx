package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.EDebuggerState;
import vshaxeDebug.DebuggerCommand;

class FrameDown extends DebuggerCommand {
   
    public function new(context:Context) {
        super(context);
    }

    override function execute() {
        debugger.send("down");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var line = lines[0];
        context.onEvent(FrameDown);
        setDone();
     }
}
