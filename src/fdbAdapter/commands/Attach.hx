package fdbAdapter.commands;

import vshaxeDebug.commands.BaseCommand;
import vshaxeDebug.Types;
import vscode.debugProtocol.DebugProtocol;

class Attach extends BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {
	override public function execute() {
		debugger.queueSend("run", function(_):Bool {
			return true;
		});
		context.sendToOutput("waiting..", OutputEventCategory.Stdout);
	}
}
