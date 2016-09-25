package fdbAdapter.commands.fdb;

import fdbAdapter.commands.DebuggerCommand;
import protocol.debug.Types.Breakpoint;

class RemoveBreakpoint extends DebuggerCommand {

    var breakpoint:Breakpoint;

    public function new(context:Context, breakpoint:Breakpoint) {
        this.breakpoint = breakpoint;
        super( context );
    }

    override function execute() {
        var filePath:String = breakpoint.source.path;
        var line = breakpoint.line;
        var splited = filePath.split("\\");
        var fname = splited.pop();
        debugger.send('clear $fname:${line}');
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        trace('RemoveBreakpoint: $lines');
        setDone();
    }
}
