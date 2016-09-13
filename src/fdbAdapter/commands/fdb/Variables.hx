package fdbAdapter.commands.fdb;

import protocol.debug.Types.VariablesResponse;
import protocol.debug.Types.VariablesArguments;
import fdbAdapter.types.VariableType;

enum VarRequestType {
    Locals(frameId:Int);
    ObjectDetails(name:String);
}

class Variables extends DebuggerCommand {

    var args:VariablesArguments;
    var response:VariablesResponse;
    var requestType:VarRequestType; 
    
    public function new(context:Context, response:VariablesResponse, args:VariablesArguments) {
        super(context);

        this.args = args;
        this.response = response;

        var id = args.variablesReference;
        var varId:String = context.variableHandles.get(id);
        requestType = getRequestType(varId);
    }

    override public function execute() {
        var command:String = switch (requestType) {
            case Locals(frameId):
                 "info locals";

            case ObjectDetails(name):
                'print $name.';
        }
        debugger.send(command);
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var variables = [];
        var rVar = ~/^(.*) = (.*)$/;

        var parentName = switch (requestType) {
            case Locals(_):
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

    function getRequestType(varId:String):VarRequestType {
        var parts:Array<String> = varId.split("_");
        var requestType = parts[0];
        return switch (requestType) {
            case "local":
                Locals(Std.parseInt(parts[1]));
            case "object":
                ObjectDetails(parts[1]);
            case _:
                throw "unrecognized";
        }
    }
}
