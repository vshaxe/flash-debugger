package fdbAdapter;

import fdbAdapter.commands.DebuggerCommand;

interface IDebugger {
    
    function start():Void;
    function queueCommand(command:DebuggerCommand):Void;
    function send(command:String):Void;
}