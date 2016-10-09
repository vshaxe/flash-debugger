package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;

class FrameUp extends DebuggerCommand {
   
    public function new(context:Context) {
        super(context);
    }

    override function execute() {
        debugger.send("up");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var line = lines[0];
        context.onEvent(FrameUp);
        setDone();
     }
}
