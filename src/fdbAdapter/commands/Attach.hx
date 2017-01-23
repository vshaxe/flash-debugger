package fdbAdapter.commands;

import vshaxeDebug.Types;
import vshaxeDebug.commands.BaseCommand;
import protocol.debug.Types;

class Attach extends BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {

    override public function execute() {
        debugger.queueSend("run", function(_):Bool {
            return true;
        });
        context.sendToOutput("waiting..", OutputEventCategory.stdout);
    }
}