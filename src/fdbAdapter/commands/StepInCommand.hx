package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.StopReason;
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
        
        protocol.sendResponse( response );
        protocol.sendEvent(new StoppedEventImpl(StopReason.step, 1));
        setDone();
     }
}
