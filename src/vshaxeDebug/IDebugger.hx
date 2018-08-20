package vshaxeDebug;

interface IDebugger {
	var parser(default, null):IParser;
	var commandBuilder(default, null):ICommandBuilder;
	function start():Void;
	function stop():Void;
	function send(command:String):Void;
	function queueSend(command:String, ?callback:Array<String>->Bool):Void;
}
