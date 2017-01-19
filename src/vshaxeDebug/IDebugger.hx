package vshaxeDebug;

interface IDebugger {
    
    function start():Void;
    function stop():Void;
    function send(command:String):Void;
    function queueSend(command:String, ?callback:Array<String> -> Bool):Void;

    var translator(default, null):ITranslator;
}
