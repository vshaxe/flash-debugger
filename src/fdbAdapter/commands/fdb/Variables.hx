package fdbAdapter.commands.fdb;

import protocol.debug.Types.VariablesResponse;
import protocol.debug.Types.VariablesArguments;
import fdbAdapter.types.VariableType;
import fdbAdapter.types.VarRequestType;

class Variables extends DebuggerCommand {

    var args:VariablesArguments;
    var response:VariablesResponse;
    var requestType:VarRequestType;
    
    public function new(context:Context, response:VariablesResponse, requestType:VarRequestType) {
        super(context);
        this.response = response;
        this.requestType = requestType;
    }

    override public function execute() {
        var command:String = switch (requestType) {
            case Locals(frameId):
                "info locals";
            case Global(frameId):
                "info global";
            case Closure(fameId):
                "print this.";
            case ObjectDetails(name):
                'print $name.';
        }
        debugger.send(command);
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var variables = [];
        var rVar = ~/^(.*) = (.*)$/;

        var parentName = switch (requestType) {
            case Locals(_) | Global(_) | Closure(_): 
                "";
            case ObjectDetails(name):
                '$name.';
        };
        
        for (line in lines) {
            if (rVar.match(line)) {
                var name = rVar.matched(1);
                var value = rVar.matched(2);
                var type = FDBOutputParseHelper.detectExpressionType(value);
                var vRef = 0;

                if (type == VariableType.Object)
                    vRef = context.variableHandles.create('object_$parentName$name');
                    
                variables.push({
                    name: name,
                    type: type,
                    value: value,
                    variablesReference: vRef 
                });
            }
        }
        response.body = {
            variables : variables
        };
        protocol.sendResponse(response);
        setDone();
    }
}
