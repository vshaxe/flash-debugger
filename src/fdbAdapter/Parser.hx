package fdbAdapter;

import vshaxeDebug.Types;
import protocol.debug.Types;
import haxe.ds.Option;

class Parser implements vshaxeDebug.IParser {
	var prompt:String;
	var promptLength:Int;
	var eolSign:String;

	public function new(eolSign:String) {
		prompt = "(fdb) ";
		promptLength = prompt.length;
		this.eolSign = eolSign;
	}

	public function parseFunctionArguments(lines:Array<String>):Array<VariableItem>
		return parseVariables(lines);

	public function parseGlobalVariables(lines:Array<String>):Array<VariableItem>
		return parseVariables(lines);

	public function parseLocalVariables(lines:Array<String>):Array<VariableItem>
		return parseVariables(lines);

	public function parseMembers(lines:Array<String>):Array<VariableItem> {
		lines.shift();
		return parseVariables(lines);
	}

	public function parseObjectProperties(lines:Array<String>):Array<VariableItem> {
		lines.shift();
		return parseVariables(lines);
	}

	public function parseEvaluate(lines:Array<String>):Option<VariableItem> {
		var variables:Array<VariableItem> = parseVariables(lines);
		trace(variables);
		return (variables.length > 0) ? Some(variables[0]) : None;
	}

	public function parseStackTrace(lines:Array<String>, pathProvider:String->String):Array<StackFrame> {
		function maybeAddSource(frame:StackFrame, name:String) {
			if (name != "<null>") {
				frame.source = {name: name, path: pathProvider(name)};
			}
		}

		var result:Array<StackFrame> = [];
		var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='(.+)'\]\.(.+)\(.*\) at (.*):([0-9]+).*/;
		var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
		var globalCall = ~/#([0-9]+)\s+(.*)\(\) at (.*):([0-9]+)/;
		for (l in lines) {
			if (rMethod.match(l)) {
				var frame = {
					id: Std.parseInt(rMethod.matched(1)),
					name: rMethod.matched(2) + "." + rMethod.matched(3),
					line: Std.parseInt(rMethod.matched(5)),
					column: 0
				};
				maybeAddSource(frame, rMethod.matched(4));
				result.push(frame);
			} else if (anonFunction.match(l)) {
				var frame = {
					id: Std.parseInt(anonFunction.matched(1)),
					name: anonFunction.matched(2) + "." + anonFunction.matched(3),
					line: Std.parseInt(anonFunction.matched(5)),
					column: 0
				};
				maybeAddSource(frame, anonFunction.matched(4));
				result.push(frame);
			} else if (globalCall.match(l)) {
				result.push({
					id: Std.parseInt(globalCall.matched(1)),
					name: globalCall.matched(2),
					line: Std.parseInt(globalCall.matched(4)),
					column: 0
				});
			}
		}
		return result;
	}

	public function parseAddBreakpoint(lines:Array<String>):Option<BreakpointInfo> {
		var result:Option<BreakpointInfo> = None;
		var breakpointData = lines[0];
		var r = ~/Breakpoint ([0-9]+).*: file ([0-9A-Za-z\.]+), line ([0-9]+)/;
		if (r.match(breakpointData)) {
			result = Some({
				id: Std.parseInt(r.matched(1)),
				fileName: r.matched(2),
				line: Std.parseInt(r.matched(3))
			});
		}
		return result;
	}

	public function parseShowFiles(lines:Array<String>):Array<SourceInfo> {
		var result:Array<SourceInfo> = [];
		var rRow = ~/^([0-9]+) (.+), ([a-zA-Z0-9:.]+)$/;
		for (l in lines) {
			if (rRow.match(l)) {
				result.push({
					name: rRow.matched(3),
					path: rRow.matched(2)
				});
			}
		}
		return result;
	}

	public function getLines(rawInput:String):Array<String> {
		return rawInput.split(eolSign);
	}

	public function getLinesExceptPrompt(rawInput:String):Array<String> {
		var withoutPrompt:String = rawInput.substring(0, rawInput.length - promptLength);
		return getLines(withoutPrompt);
	}

	public function getTraces(rawInput:String):Array<String> {
		var result:Array<String> = [];
		var lines = getLines(rawInput);
		var traceR = ~/\[trace\](.*)/;
		for (line in lines) {
			if (traceR.match(line)) {
				result.push(line);
			}
		}
		return result;
	}

	public function isPromptMatched(rawInput:String):Bool {
		return (rawInput.substr(-promptLength) == prompt);
	}

	public function isExitMatched(rawInput:String):Bool {
		var exitR = ~/\[UnloadSWF\]/;
		return (exitR.match(rawInput));
	}

	public function isGreetingMatched(lines:Array<String>):Bool {
		var firstLine = lines[0];
		return (firstLine != null) ? (firstLine.substr(0, 5) == "Adobe") : false;
	}

	public function isStopOnBreakpointMatched(lines:Array<String>):Bool {
		for (line in lines) {
			var r = ~/Breakpoint ([0-9]+),(.*) (.+).hx:([0-9]+)/;
			if (r.match(line)) {
				return true;
			}
		}
		return false;
	}

	public function isStopOnExceptionMatched(lines:Array<String>):Bool {
		for (line in lines) {
			var r = ~/^\[Fault\].*/;
			if (r.match(line)) {
				return true;
			}
		}
		return false;
	}

	function parseVariables(lines:Array<String>):Array<VariableItem> {
		var rVar = ~/^(.*) = (.*)$/;
		var result:Array<VariableItem> = [];

		for (line in lines) {
			if (rVar.match(line)) {
				var name = StringTools.trim(rVar.matched(1));
				var value = rVar.matched(2);
				var type = detectExpressionType(value);

				result.push({
					name: name,
					type: type,
					value: value
				});
			}
		}

		return result;
	}

	function detectExpressionType(expr:String):VariableType {
		var rObjectType = ~/^\[Object (\d+),/;
		var rIntType = ~/^\d+ \(0\x\d+\)/;
		var rFloatType = ~/^\d+\.\d+$/;
		var rStringType = ~/^[\\"].*[\\"]$/;
		var rBoolType = ~/^[t|f]\S+$/;

		return if (rObjectType.match(expr)) {
			var objectId = Std.parseInt(rObjectType.matched(1));
			Object(objectId);
		} else if (rIntType.match(expr))
			Simple("Int");
		else if (rFloatType.match(expr))
			Simple("Float");
		else if (rStringType.match(expr))
			Simple("String");
		else if (rBoolType.match(expr))
			Simple("Bool");
		else
			Simple("Unknown");
	}
}
