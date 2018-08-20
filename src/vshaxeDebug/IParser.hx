package vshaxeDebug;

import protocol.debug.Types;
import vshaxeDebug.Types;
import haxe.ds.Option;

interface IParser {
	function parseStackTrace(lines:Array<String>, pathProvider:String->String):Array<StackFrame>;
	function parseLocalVariables(lines:Array<String>):Array<VariableItem>;
	function parseFunctionArguments(lines:Array<String>):Array<VariableItem>;
	function parseGlobalVariables(lines:Array<String>):Array<VariableItem>;
	function parseObjectProperties(lines:Array<String>):Array<VariableItem>;
	function parseMembers(lines:Array<String>):Array<VariableItem>;
	function parseEvaluate(lines:Array<String>):Option<VariableItem>;
	function parseAddBreakpoint(lines:Array<String>):Option<BreakpointInfo>;
	function parseShowFiles(lines:Array<String>):Array<SourceInfo>;
	function getLines(rawInput:String):Array<String>;
	function getLinesExceptPrompt(rawInput:String):Array<String>;
	function getTraces(rawInput:String):Array<String>;
	function isPromptMatched(rawInput:String):Bool;
	function isGreetingMatched(lines:Array<String>):Bool;
	function isStopOnBreakpointMatched(lines:Array<String>):Bool;
	function isStopOnExceptionMatched(lines:Array<String>):Bool;
	function isExitMatched(rawInput:String):Bool;
}
