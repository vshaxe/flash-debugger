package fdbAdapter.commands.fdb;

import protocol.debug.Types;

class StackTrace extends DebuggerCommand
{
    var response:StackTraceResponse;

    public function new(context:Context, response:StackTraceResponse) 
    {
        this.response = response;
        super(context);
    }

    override function execute()
    {
        debugger.send('bt');
    }

    override public function processDebuggerOutput(lines:Array<String>):Void
    {
        var frames = [];
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='([0-9a-zA-Z\.:]+)'\]\.[a-zA-Z0-9\/]+.*\) at ([a-zA-Z0-9\.]+):([0-9]+).*/;
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='(.+)'\]\.(.+)\(.*\) at (.*):([0-9]+).*/;
        var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
        var globalCall = ~/#([0-9]+)\s+(.*)\(\) at (.*):([0-9]+)/;
        var l = lines[8];
        for (l in lines)
        {
            var frame = 
            if (rMethod.match(l))
            {
                {
                    id : Std.parseInt(rMethod.matched(1))
                    , name : rMethod.matched(2) + "." + rMethod.matched(3) 
                    , line : Std.parseInt( rMethod.matched(5))
                    , source : { name : rMethod.matched(4), path : calculatePath(context.sourcePath, rMethod.matched(2), rMethod.matched(4))}
                    , column : 0 
                };
            }
            else if (anonFunction.match(l))
            {
                {
                    id : Std.parseInt(anonFunction.matched(1))
                    , name : anonFunction.matched(2) + "." + anonFunction.matched(3) 
                    , line : Std.parseInt( anonFunction.matched(5))
                    , source : { name : anonFunction.matched(4), path : calculatePath(context.sourcePath, anonFunction.matched(2), anonFunction.matched(4))}
                    , column : 0 
                };
               
            }
            else if (globalCall.match(l))
            {
                {
                    id : Std.parseInt(globalCall.matched(1))
                    , name : globalCall.matched(2)
                    , line : Std.parseInt( globalCall.matched(4))
                    , source : { path : "global", name: "global"}
                    , column : 0 
                };
            }
            else
                null;

            if (frame != null)
            {
                frames.push(frame);
            }
        }
        response.body = {
            stackFrames : frames
        };

        switch (context.debuggerState)
        {
            case EDebuggerState.Stopped(_, currentFrame):
                context.debuggerState = EDebuggerState.Stopped(frames, currentFrame);
            
            default:
                throw "wrong state";
        }

        protocol.sendResponse(response);
        setDone();
    }

    function calculatePath(basePath:String, className:String, fileName:String):String
    {
        StringTools.replace(className, "$","");
        var parts:Array<String> = className.split("::");
        var delimiter = "\\";
        var path = StringTools.replace(parts[0], ".", delimiter);
        return '$basePath$delimiter$path$delimiter$fileName';
    }
}