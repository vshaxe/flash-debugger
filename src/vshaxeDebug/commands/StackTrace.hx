package vshaxeDebug.commands;

import protocol.debug.Types;
import vshaxeDebug.Types;

class StackTrace extends BaseCommand<StackTraceResponse, StackTraceArguments> {
	var frames:Array<StackFrame> = [];

	override public function execute() {
		var batch = new CommandsBatch(context.debugger, callback);
		if (Lambda.count(context.fileNameToFullPathDict) == 0) {
			batch.add(cmd.showFiles(), processShowFilesResult);
		}
		batch.add(cmd.stackTrace(), processStackTraceResult);
	}

	function callback() {
		response.body = {
			stackFrames: frames
		};
		context.onEvent(SetFrames(frames));
		context.protocol.sendResponse(response);
	}

	function processShowFilesResult(lines:Array<String>):Bool {
		var sources:Array<SourceInfo> = parser.parseShowFiles(lines);
		for (source in sources) {
			context.fileNameToFullPathDict.set(source.name, source.path);
		}
		return true;
	}

	function processStackTraceResult(lines:Array<String>):Bool {
		var frames = parser.parseStackTrace(lines, pathProvider);
		response.body = {
			stackFrames: frames
		};
		context.onEvent(SetFrames(frames));
		context.protocol.sendResponse(response);
		return true;
	}

	function pathProvider(fileName:String):String {
		trace(fileName);
		trace(context.fileNameToFullPathDict.exists(fileName));
		trace(context.fileNameToFullPathDict.get(fileName));
		return context.fileNameToFullPathDict.get(fileName);
	}
}
