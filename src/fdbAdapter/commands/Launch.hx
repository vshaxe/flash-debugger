package fdbAdapter.commands;

import vshaxeDebug.Types;
import vshaxeDebug.commands.BaseCommand;
import protocol.debug.Types;
import vshaxeDebug.PathUtils;
import js.node.Fs;

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
		debugger.queueSend(cmd.launch(program), processResult);
		context.sendToOutput('running $program', OutputEventCategory.stdout);
	}

	function processResult(lines:Array<String>):Bool {
		var matchingOutputLine = lines[lines.length - 1];
		trace('Launch: $lines');
		for (line in lines) {
			if (matchSWFConnected(line)) {
				context.protocol.sendResponse(response);
				context.sendToOutput("launch success", OutputEventCategory.stdout);
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
