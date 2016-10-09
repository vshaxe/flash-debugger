package fdbAdapter;

import vshaxeDebug.types.VariableType;

class OutputParseHelper
{
    public static function detectExpressionType(expr:String)
    {
        var rObjectType = ~/^\[Object (\d+),/;
        var rIntType = ~/^\d+ \(0\x\d+\)/;
        var rFloatType = ~/^\d+\.\d+$/;
        var rStringType = ~/^[\\"].*[\\"]$/; 
        var rBoolType = ~/^[t|f]\S+$/;

        return if (rObjectType.match(expr)) {
            var objectId = Std.parseInt(rObjectType.matched(1));
            VariableType.Object(objectId);
        }
        else if (rIntType.match(expr))
            VariableType.Simple("Int");
        else if (rFloatType.match(expr))
            VariableType.Simple("Float");
        else if (rStringType.match(expr))
            VariableType.Simple("String");
        else if (rBoolType.match(expr))
            VariableType.Simple("Bool");
        else
            VariableType.Simple("Unknown");
    }
}
