package fdbAdapter.commands.fdb;

class Continue extends DebuggerCommand {
    
    override function execute() {
        debugger.send("c");
        context.debuggerState = Running;
        setDone();
    }
}
