package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.NextResponse;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;

class NextCommand extends DebuggerCommand {

    var response:NextResponse;

    public function new(context:Context, response:NextResponse) {
        this.response = response;
        super(context);
    }

    override function execute() {
        debugger.send("next");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var line = lines[0];
        var rStopeed = ~/Execution halted, (\S)+:([0-9]+)/;
        //if (rStopeed.match(line)) {
            protocol.sendResponse( response );
            protocol.sendEvent(new StoppedEventImpl("step", 1));
            setDone();
        //}
        //else
        //   trace( 'StepOut FAILED: [ $lines ]');
     }
}
