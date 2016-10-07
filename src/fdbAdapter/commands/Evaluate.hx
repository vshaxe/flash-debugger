package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import vshaxeDebug.types.VariableType;
import protocol.debug.Types.EvaluateResponse;
import protocol.debug.Types.EvaluateArguments;

class Evaluate extends DebuggerCommand {

    var response:EvaluateResponse;
    var expr:String;
    
    public function new(context:Context, response:EvaluateResponse, args:EvaluateArguments) {
        super(context);
        
        expr = args.expression;
        this.response = response;
    }

    override public function execute() {
        var preparedExpression:String = prepareExpression(expr);
        var command:String = 'print $preparedExpression';
        debugger.send(command);
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var variables = [];
        var rVar = ~/^(.*) = (.*)$/;
        var cantEvaluate = ~/Expression could not be evaluated./;
    
        var line = lines[0];        
        response.body = {
            result : line
            , variablesReference : 0
        };

        if (rVar.match(line)) {
            var name = rVar.matched(1);
            var value = rVar.matched(2);            
            var type = OutputParseHelper.detectExpressionType(value);
            switch (type) {
                case Object(id):
                    var vRef = context.variableHandles.create('object_$id');
                    response.body.variablesReference = vRef;
                default:
            }
        }

        protocol.sendResponse(response);
        setDone();
    }

    function prepareExpression(raw:String):String {
        var dotStarts = ~/^\..*/;
        var colonStarts = ~/^:.*/;
        if (dotStarts.match(raw)) {
            return 'this$raw';
        } 
        else if (colonStarts.match(raw)) {
            return "";
        }
        return raw;
    }
}
