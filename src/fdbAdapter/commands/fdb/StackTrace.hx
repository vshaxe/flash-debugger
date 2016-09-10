package fdbAdapter.commands.fdb;

import protocol.debug.Types;
import adapter.ProtocolServer;

class StackTrace extends DebuggerCommand
{
    var response:StackTraceResponse;
    var sourceBase:String;

    public function new(protocol:ProtocolServer, debugger:IDebugger, response:StackTraceResponse, sourceBase:String) 
    {
        this.response = response;
        this.sourceBase = sourceBase;
        super( protocol, debugger );
    }

    override function execute()
    {
        debugger.send('bt');
    }

    override public function processDebuggerOutput(lines:Array<String>):Void
    {
        var frames = [];
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='([0-9a-zA-Z\.:]+)'\]\.[a-zA-Z0-9\/]+.*\) at ([a-zA-Z0-9\.]+):([0-9]+).*/;
        for (l in lines)
        {
            if (rMethod.match(l))
            {
                var frame = {
                    id : Std.parseInt(rMethod.matched(1))
                    , name : rMethod.matched(3)
                    , line : Std.parseInt( rMethod.matched(4))
                    , source : { name : rMethod.matched(3), path : calculatePath(sourceBase, rMethod.matched(2), rMethod.matched(3))}
                    , column : 0 
                };
                frames.push(frame);
            }
        }
        response.body = {
            stackFrames : frames
        };
        protocol.sendResponse(response);
        done = true;
    }

    function calculatePath(basePath:String, className:String, fileName:String):String
    {
        var parts:Array<String> = className.split("::");
        var delimiter = "\\";
        var path = StringTools.replace(parts[0], ".", delimiter);
        return '$basePath$delimiter$path$delimiter$fileName';
    }
}