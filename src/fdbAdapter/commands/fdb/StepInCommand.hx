package fdbAdapter.commands.fdb;

import protocol.debug.Types.StepInResponse;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;

class StepInCommand extends DebuggerCommand {

    var response:StepInResponse;

    public function new(context:Context, response:StepInResponse) {
        this.response = response;
        super(context);
    }

    override function execute() {
        debugger.send("step");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        trace(lines);
        var line = lines[0];
        var rStopeed = ~/Execution halted, (\S)+:([0-9]+)/;
        //if (rStopeed.match(line)) {
            protocol.sendResponse( response );
            protocol.sendEvent(new StoppedEventImpl("step", 1));
            setDone();
        //}
        //else
        //   trace( 'StepIn FAILED: [ $lines ]');
     }
}