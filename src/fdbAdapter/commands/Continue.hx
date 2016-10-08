package fdbAdapter.commands;

import vshaxeDebug.DebuggerCommand;

class Continue extends DebuggerCommand {
    
    override function execute() {
        debugger.send("c");
        context.onEvent(Continue);
        setDone();
    }
}
