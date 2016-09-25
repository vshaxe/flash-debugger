package fdbAdapter.commands.fdb;

class Pause extends DebuggerCommand {
    
    override function execute() {
        debugger.send("break");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        trace('Pause: $lines');
        setDone();
    }
}
