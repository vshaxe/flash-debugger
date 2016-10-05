package fdbAdapter.commands;

import vshaxeDebug.DebuggerCommand;

class StopForBreakpointsSetting extends DebuggerCommand {

    override function execute() {
        debugger.send("");
        debugger.send("y");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        setDone();
    }
}
