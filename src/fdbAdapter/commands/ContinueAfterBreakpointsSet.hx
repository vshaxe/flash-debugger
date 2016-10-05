package fdbAdapter.commands;

import vshaxeDebug.DebuggerCommand;

class ContinueAfterBreakpointsSet extends DebuggerCommand {
    
    override function execute() {
        debugger.send("c");
        setDone();
    }
}
