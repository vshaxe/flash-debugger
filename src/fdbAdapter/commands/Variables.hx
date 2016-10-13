package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.EScope;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.Variable;
import protocol.debug.Types.VariablesArguments;

class Variables extends DebuggerCommand {

    var args:VariablesArguments;
    var variables:Array<Variable>;
    var scope:EScope;
    
    public function new(context:Context, scope:EScope, result:Array<Variable>) {
        super(context);
        this.scope = scope;
        this.variables = result;
    }

    override public function execute() {
        var command:String = switch (scope) {
            case Locals(frameId, LocalVariables):
                "info locals";
            case Locals(frameId, FunctionArguments):
                "info arguments";
            case Locals(frameId, NotSpecified):
                "info locals";
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
        var rVar = ~/^(.*) = (.*)$/;
        var parentName = "";

        switch (scope) {
            case Closure(_):
                lines.shift();
            case ObjectDetails(id, name):
                lines.shift();
                parentName = '$name';
            default:
        };
        
        for (line in lines) {
            if (rVar.match(line)) {
                var name = StringTools.trim(rVar.matched(1));
                var value = rVar.matched(2);
                var type = OutputParseHelper.detectExpressionType(value);
                var vRef = 0;

                var varType:String = switch (type)
                {
                    case Object(id):
                        vRef = context.variableHandles.create('object_$id');                        
                        context.knownObjects.set(id, joinWithParent(name, parentName));
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

        trace('Variables: $variables');
        setDone();
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
