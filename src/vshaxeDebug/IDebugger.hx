package vshaxeDebug;

interface IDebugger {
    
    function start():Void;
    function stop():Void;
    function queueCommand(command:DebuggerCommand):Void;
    function send(command:String):Void;
}
