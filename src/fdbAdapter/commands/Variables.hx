package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.VariablesResponse;
import protocol.debug.Types.VariablesArguments;
import vshaxeDebug.types.VariableType;
import vshaxeDebug.types.VarRequestType;

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
            case Arguments(frameId):
                "info arguments";
            case Global(frameId):
                "info global";
            case Closure(fameId):
                "print this.";
            case ObjectDetails(_, name):
                'print $name.';
        }
        debugger.send(command);
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var variables = [];
        var rVar = ~/^(.*) = (.*)$/;

        var parentName = "";

        switch (requestType) {
            case Closure(_):
                lines.shift();
            case ObjectDetails(id, name):
                lines.shift();
                parentName = '$name.';
            default:
        };
        
        for (line in lines) {
            if (rVar.match(line)) {
                var name = rVar.matched(1);
                var value = rVar.matched(2);
                var type = OutputParseHelper.detectExpressionType(value);
                var vRef = 0;

                var varType:String = switch (type)
                {
                    case Object(id):
                        vRef = context.variableHandles.create('object_$id');
                        context.knownObjects.set(id, '$parentName$name');
                        "Object";
                    case Simple(type):
                        type;
                }
                    
                variables.push({
                    name: name,
                    type: varType,
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
