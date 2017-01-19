package vshaxeDebug;

import protocol.debug.Types;
import vshaxeDebug.Types;
import haxe.ds.Option;

interface ITranslator {

    function cmdLaunch(program:String):String;
    function cmdFrameUp():String;
    function cmdFrameDown():String;
    function cmdStepIn():String;
    function cmdStepOut():String;
    function cmdNext():String;
    function cmdContinue():String;
    function cmdPause():String;
    function cmdStackTrace():String;
    function cmdAddBreakpoint(fileName:String, filePath:String, line:Int):String;
    function cmdRemoveBreakpoint(fileName:String, filePath:String, line:Int):String;
    function cmdPrintLocalVariables():String;
    function cmdPrintFunctionArguments():String;
    function cmdPrintGlobalVariables():String;
    function cmdPrintObjectProperties(?objectName:String):String;
    function cmdPrintMembers():String;
    function cmdEvaluate(expr:String):String;
    function cmdShowFiles():String;

    function parseStackTrace(lines:Array<String>, pathProvider:String -> String):Array<StackFrame>;
    function parseLocalVariables(lines:Array<String>):Array<VariableItem>;
    function parseFunctionArguments(lines:Array<String>):Array<VariableItem>;
    function parseGlobalVariables(lines:Array<String>):Array<VariableItem>;
    function parseObjectProperties(lines:Array<String>):Array<VariableItem>;
    function parseMembers(lines:Array<String>):Array<VariableItem>;
    function parseEvaluate(lines:Array<String>):Option<VariableItem>;
    function parseAddBreakpoint(lines:Array<String>):Option<BreakpointInfo>;
}