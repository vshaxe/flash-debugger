package fdbAdapter.commands.fdb;

class ContinueAfterBreakpointsSet extends DebuggerCommand {
    
    override function execute() {
        debugger.send("c");
        setDone();
    }
}
