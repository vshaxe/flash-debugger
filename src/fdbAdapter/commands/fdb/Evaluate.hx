package fdbAdapter.commands.fdb;

import fdbAdapter.types.VariableType;
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
        var command:String = 'print $expr';
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
            var type = FDBOutputParseHelper.detectExpressionType(value);
            
            if (type == VariableType.Object) {
                var vRef = context.variableHandles.create('object_$name');
                response.body.variablesReference = vRef;
            }
        }

        protocol.sendResponse(response);
        setDone();
    }

}
