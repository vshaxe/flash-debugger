package vshaxeDebug.commands;

import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import haxe.ds.Option;
import haxe.io.Path;
import protocol.debug.Types;
import vshaxeDebug.Types;

class SetBreakpoints extends BaseCommand<SetBreakpointsResponse, SetBreakpointsArguments> {
	var result:Array<Breakpoint>;

	override public function execute() {
		result = [];

		if (args.source.name == null) {
			args.source.name = Path.withoutDirectory(args.source.path);
		}

		var source = new SourceImpl(args.source.name, args.source.path);
		var pathKey = getKey(args.source.name);

		if (!context.breakpoints.exists(pathKey)) {
			context.breakpoints.set(pathKey, []);
		}

		var breakpoints = context.breakpoints.get(pathKey);
		var previouslySet = getAlreadySetMap(pathKey, context.breakpoints);
		var batch = new CommandsBatch(context.debugger, commandDoneCallback.bind(pathKey, response));

		switch (context.debuggerState) {
			case EDebuggerState.Running:
				batch.add(cmd.pause(), function(_):Bool {
					return true;
				});
			default:
		}

		for (b in args.breakpoints) {
			if (previouslySet.exists(b.line)) {
				previouslySet.remove(b.line);
			} else {
				var breakpoint:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
				var cmd:String = cmd.addBreakpoint(args.source.name, args.source.path, b.line);
				batch.add(cmd, onBreakpointAdded.bind(breakpoint, breakpoints));
			}
		}

		for (b in previouslySet) {
			var cmd:String = cmd.removeBreakpoint(b.source.name, b.source.path, b.line);
			batch.add(cmd, onBreakpointRemoved.bind(b, breakpoints));
		}

		switch (context.debuggerState) {
			case EDebuggerState.Running:
				batch.add(cmd.continueCommand());
			default:
		}
		batch.checkIsDone();
	}

	function onBreakpointAdded(breakpoint:Breakpoint, container:Array<Breakpoint>, lines:Array<String>):Bool {
		var info:Option<BreakpointInfo> = parser.parseAddBreakpoint(lines);
		switch (info) {
			case Some(bInfo):
				breakpoint.id = bInfo.id;
				breakpoint.source.name = bInfo.fileName;
				breakpoint.line = bInfo.line;
				container.push(breakpoint);
			default:
				this.context.sendError(response, 'AddBreakpoint FAILED: [ $lines ]');
		}
		return true;
	}

	function onBreakpointRemoved(breakpoint:Breakpoint, container:Array<Breakpoint>, lines:Array<String>):Bool {
		container.remove(breakpoint);
		return true;
	}

	function commandDoneCallback(path:String, response:SetBreakpointsResponse) {
		var breakpoints:Array<Breakpoint> = context.breakpoints.get(path);
		var validated = [for (b in breakpoints) if (b.id > 0) b];
		context.breakpoints.set(path, validated);
		response.success = true;
		response.body = {
			breakpoints: validated
		};
		context.protocol.sendResponse(response);
	}

	function getAlreadySetMap(path:String, breakpoints:Map<String, Array<Breakpoint>>):Map<Int, Breakpoint> {
		var res = new Map<Int, Breakpoint>();
		if (breakpoints.exists(path)) {
			var addedForThisPath:Array<Breakpoint> = breakpoints.get(path);
			for (b in addedForThisPath) {
				res.set(b.line, b);
			}
		}
		return res;
	}

	function getKey(path:String):String {
		var res = StringTools.replace(path, "\\", "/");
		return res;
	}
}
