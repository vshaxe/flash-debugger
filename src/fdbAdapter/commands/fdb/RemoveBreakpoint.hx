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
        var line = breakpoint.line;
        var fname = breakpoint.source.name;
        debugger.send('clear $fname:${line}');
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        trace('RemoveBreakpoint: $lines');
        setDone();
    }
}
