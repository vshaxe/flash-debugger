package vshaxeDebug.commands;

import vshaxeDebug.Types;
import protocol.debug.Types;
import haxe.ds.Option;

class Variables extends BaseCommand<VariablesResponse, VariablesArguments> {
	var scope:EScope;
	var result:Array<Variable>;

	override public function execute() {
		var id = args.variablesReference;
		var handleId:String = context.variableHandles.get(id);
		scope = getScopeOfHandle(handleId);
		result = [];

		var framesDiff:Int = getFramesDiff(scope);

		var batch = new CommandsBatch(context.debugger, callback);
		if (framesDiff != 0) {
			for (i in 0...Math.floor(Math.abs(framesDiff))) {
				if (framesDiff < 0)
					batch.add(cmd.frameUp());
				else
					batch.add(cmd.frameDown());
			}
		}

		switch (scope) {
			case Locals(frameId, _):
				batch.add(cmd.printLocalVariables(), processResult.bind(parser.parseLocalVariables));
				batch.add(cmd.printFunctionArguments(), processResult.bind(parser.parseFunctionArguments));
			case Global(frameId):
				batch.add(cmd.printGlobalVariables(), processResult.bind(parser.parseGlobalVariables));
			case Closure(fameId):
				batch.add(cmd.printMembers(), processResult.bind(parser.parseMembers));
			case ObjectDetails(_, name):
				batch.add(cmd.printObjectProperties(name), processResult.bind(parser.parseObjectProperties, _, name));
		}
	}

	function callback() {
		response.body = {
			variables: result
		};
		context.protocol.sendResponse(response);
	}

	function processResult(parser:Array<String>->Array<VariableItem>, lines:Array<String>, parentName:String = ""):Bool {
		var variableItems:Array<VariableItem> = parser(lines);
		for (item in variableItems) {
			var vRef = 0;
			var varType:String = switch (item.type) {
				case Object(id):
					vRef = context.variableHandles.create('object_$id');
					context.knownObjects.set(id, joinWithParent(item.name, parentName));
					"Object";
				case Simple(type):
					type;
			}

			result.push({
				name: item.name,
				type: varType,
				value: item.value,
				variablesReference: vRef
			});
		}
		return true;
	}

	function getScopeOfHandle(handleId:String):EScope {
		var parts:Array<String> = handleId.split("_");
		var prefix = parts[0];

		return switch (prefix) {
			case "locals":
				Locals(Std.parseInt(parts[1]), ScopeLocalsType.NotSpecified);
			case "globals":
				Global(Std.parseInt(parts[1]));
			case "members":
				Closure(Std.parseInt(parts[1]));
			case "object":
				var objectId:Int = Std.parseInt(parts[1]);
				var objectName:String = context.knownObjects.get(objectId);
				ObjectDetails(objectId, objectName);
			case _:
				throw "could not recognize";
		}
	}

	function getFramesDiff(scope:EScope):Int {
		var frameId:Option<Int> = switch (scope) {
			case Locals(frameId, _):
				Some(frameId);
			case Global(frameId):
				Some(frameId);
			case Closure(frameId):
				Some(frameId);
			default:
				None;
		}

		var currentFrame = switch (context.debuggerState) {
			case Stopped(frames, currentFrame):
				Some(currentFrame);
			default:
				None;
		}

		return switch [frameId, currentFrame] {
			case [Some(requestedFrame), Some(currentFrame)]:
				currentFrame - requestedFrame;
			default:
				0;
		}
	}

	function joinWithParent(name:String, parentName:String):String {
		if (parentName == "")
			return name;

		if (Std.parseInt(name) != null)
			return '$parentName[$name]';
		else
			return '$parentName.$name';
	}
}
