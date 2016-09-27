package fdbAdapter.commands.fdb;

import protocol.debug.Types.PauseResponse;


class StopForBreakpointsSetting extends DebuggerCommand {

    override function execute() {
        debugger.send("");
        debugger.send("y");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        setDone();
    }
}
