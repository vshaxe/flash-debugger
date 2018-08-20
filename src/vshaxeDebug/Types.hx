package vshaxeDebug;

import protocol.debug.Types;

typedef VariableItem = {
	var name:String;
	var type:VariableType;
	var value:String;
}

typedef BreakpointInfo = {
	var id:Int;
	var fileName:String;
	var line:Int;
}

typedef SourceInfo = {
	var name:String;
	var path:String;
}

enum VariableType {
	Object(id:Int);
	Simple(type:String);
}

@:enum
abstract ScopeLocalsType(Int) {
	var NotSpecified = 1;
	var FunctionArguments = 2;
	var LocalVariables = 3;
}

enum EScope {
	Locals(frameId:Int, type:ScopeLocalsType);
	Global(frameId:Int);
	Closure(frameId:Int);
	ObjectDetails(id:Int, name:String);
}

typedef ExtLaunchRequestArguments = {
	> LaunchRequestArguments,
	var program:String;
	@:optional var receiveAdapterOutput:Bool;
}

typedef ExtAttachRequestArguments = ExtLaunchRequestArguments;
