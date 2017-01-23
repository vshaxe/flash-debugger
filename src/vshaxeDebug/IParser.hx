package vshaxeDebug;

import protocol.debug.Types;
import vshaxeDebug.Types;
import haxe.ds.Option;

interface IParser {

    function parseStackTrace(lines:Array<String>, pathProvider:String -> String):Array<StackFrame>;
    function parseLocalVariables(lines:Array<String>):Array<VariableItem>;
    function parseFunctionArguments(lines:Array<String>):Array<VariableItem>;
    function parseGlobalVariables(lines:Array<String>):Array<VariableItem>;
    function parseObjectProperties(lines:Array<String>):Array<VariableItem>;
    function parseMembers(lines:Array<String>):Array<VariableItem>;
    function parseEvaluate(lines:Array<String>):Option<VariableItem>;
    function parseAddBreakpoint(lines:Array<String>):Option<BreakpointInfo>;
}