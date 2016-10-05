package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.StepOutResponse;
import protocol.debug.Types.StopReason;
import adapter.DebugSession.StoppedEvent as StoppedEventImpl;

class StepOutCommand extends DebuggerCommand {

    var response:StepOutResponse;

    public function new(context:Context, response:StepOutResponse) {
        this.response = response;
        super(context);
    }

    override function execute() {
        debugger.send("finish");
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var line = lines[0];
        protocol.sendResponse( response );
        protocol.sendEvent(new StoppedEventImpl(StopReason.step, 1));
        setDone();
     }
}
