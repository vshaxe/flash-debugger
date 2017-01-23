package fdbAdapter;

import vshaxeDebug.Types;
import protocol.debug.Types;
import haxe.ds.Option;

class Parser implements vshaxeDebug.IParser {

    public function new() {}

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

    public function parseStackTrace(lines:Array<String>, pathProvider:String -> String):Array<StackFrame> {
        var result = [];
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='(.+)'\]\.(.+)\(.*\) at (.*):([0-9]+).*/;
        var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
        var globalCall = ~/#([0-9]+)\s+(.*)\(\) at (.*):([0-9]+)/;
        for (l in lines) {
            if (rMethod.match(l)) {
                result.push({
                    id : Std.parseInt(rMethod.matched(1)),
                    name : rMethod.matched(2) + "." + rMethod.matched(3),
                    line : Std.parseInt( rMethod.matched(5)),
                    source : { name : rMethod.matched(4), path : pathProvider(rMethod.matched(4))},
                    column : 0 
                });
            }
            else if (anonFunction.match(l)) {
                result.push({
                    id : Std.parseInt(anonFunction.matched(1)),
                    name : anonFunction.matched(2) + "." + anonFunction.matched(3),
                    line : Std.parseInt( anonFunction.matched(5)),
                    source : { name : anonFunction.matched(4), path : pathProvider(anonFunction.matched(4))},
                    column : 0 
                });
            }
            else if (globalCall.match(l)) {
                result.push({
                    id : Std.parseInt(globalCall.matched(1)),
                    name : globalCall.matched(2),
                    line : Std.parseInt( globalCall.matched(4)),
                    source : { path : "global", name: "global"},
                    column : 0 
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
                id : Std.parseInt(r.matched(1)),
                fileName : r.matched(2),
                line : Std.parseInt(r.matched(3))
            });
        }
        return result;
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
        }
        else if (rIntType.match(expr))
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