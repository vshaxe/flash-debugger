package fdbAdapter.commands;

import vshaxeDebug.Types;
import vshaxeDebug.commands.BaseCommand;
import vscode.debugProtocol.DebugProtocol;
import vshaxeDebug.PathUtils;
import js.node.Fs;
import js.node.ChildProcess;

class Launch extends BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {
	override public function execute() {
		var program = args.program;
		if (!PathUtils.isAbsolutePath(program)) {
			if (!PathUtils.isOnPath(program)) {
				context.sendError(response, 'Cannot find runtime $program on PATH.');
				context.protocol.sendResponse(response);
				return;
			}
		} else if (!Fs.existsSync(program)) {
			response.success = false;
			response.message = 'Cannot find $program';
			context.protocol.sendResponse(response);
			return;
		}
		debugger.queueSend(cmd.launch(), processResult);
		ChildProcess.exec('"$program"', function(error, _, _) {
			if (error != null) {
				context.sendToOutput(Std.string(error));
			}
		});
		context.sendToOutput('running $program', OutputEventCategory.Stdout);
	}

	function processResult(lines:Array<String>):Bool {
		var matchingOutputLine = lines[lines.length - 1];
		trace('Launch: $lines');
		for (line in lines) {
			if (matchSWFConnected(line)) {
				context.protocol.sendResponse(response);
				context.sendToOutput("launch success", OutputEventCategory.Stdout);
				return true;
			}
		}
		return false;
	}

	function matchSWFConnected(data:String):Bool {
		return if (data == null)
			false;
		else
			(data.substr(0, 5) == "[SWF]");
	}
}
