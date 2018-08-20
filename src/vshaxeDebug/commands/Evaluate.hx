package vshaxeDebug.commands;

import vshaxeDebug.Types;
import protocol.debug.Types;
import haxe.ds.Option;

class Evaluate extends BaseCommand<EvaluateResponse, EvaluateArguments> {
	override public function execute() {
		var preparedExpression:String = prepareExpression(args.expression);
		var command:String = cmd.evaluate(preparedExpression);
		debugger.queueSend(command, processResult);
	}

	function processResult(lines:Array<String>):Bool {
		var exprResult:Option<VariableItem> = parser.parseEvaluate(lines);
		response.body = {
			result: "could not be evaluated",
			variablesReference: 0
		};
		switch (exprResult) {
			case Some(v):
				switch (v.type) {
					case Object(id):
						var vRef = context.variableHandles.create('object_$id');
						response.body.variablesReference = vRef;
					default:
				}
				response.body.result = v.value;
			default:
		}
		context.protocol.sendResponse(response);
		return true;
	}

	function prepareExpression(raw:String):String {
		var dotStarts = ~/^\..*/;
		var colonStarts = ~/^:.*/;
		if (dotStarts.match(raw)) {
			return 'this$raw';
		} else if (colonStarts.match(raw)) {
			return "";
		}
		return raw;
	}
}
