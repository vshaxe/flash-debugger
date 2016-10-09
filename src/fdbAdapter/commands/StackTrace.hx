package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.StackTraceResponse;

class StackTrace extends DebuggerCommand {

    var response:StackTraceResponse;

    public function new(context:Context, response:StackTraceResponse) {
        this.response = response;
        super(context);
    }

    override function execute() {
        debugger.send("bt");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var frames = [];
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='(.+)'\]\.(.+)\(.*\) at (.*):([0-9]+).*/;
        var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
        var globalCall = ~/#([0-9]+)\s+(.*)\(\) at (.*):([0-9]+)/;
        for (l in lines) {
            var frame = 
            if (rMethod.match(l)) {
                {
                    id : Std.parseInt(rMethod.matched(1)),
                    name : rMethod.matched(2) + "." + rMethod.matched(3),
                    line : Std.parseInt( rMethod.matched(5)),
                    source : { name : rMethod.matched(4), path : getPath(context, rMethod.matched(4))},
                    column : 0 
                };
            }
            else if (anonFunction.match(l)) {
                {
                    id : Std.parseInt(anonFunction.matched(1)),
                    name : anonFunction.matched(2) + "." + anonFunction.matched(3),
                    line : Std.parseInt( anonFunction.matched(5)),
                    source : { name : anonFunction.matched(4), path : getPath(context, anonFunction.matched(4))},
                    column : 0 
                };
               
            }
            else if (globalCall.match(l)) {
                {
                    id : Std.parseInt(globalCall.matched(1)),
                    name : globalCall.matched(2),
                    line : Std.parseInt( globalCall.matched(4)),
                    source : { path : "global", name: "global"},
                    column : 0 
                };
            }
            else
                null;

            if (frame != null) {
                frames.push(frame);
            }
        }
        response.body = {
            stackFrames : frames
        };
        context.onEvent(SetFrames(frames));
        protocol.sendResponse(response);
        setDone();
    }

    function getPath(context:Context, fileName:String):String {        
        var path:String = context.fileNameToFullPathDict.get(fileName);
        return '$path';        
    }
}
