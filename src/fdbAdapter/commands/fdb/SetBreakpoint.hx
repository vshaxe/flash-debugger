package fdbAdapter.commands.fdb;

import fdbAdapter.commands.DebuggerCommand;
import adapter.ProtocolServer;
import protocol.debug.Types;

typedef SetBreakpointResult = {
    id:Int
    , file:String
    , line:Int
}

class SetBreakpoint extends DebuggerCommand
{
    var breakpoint:Breakpoint;
    
    public function new(protocol:ProtocolServer, debugger:IDebugger, breakpoint:Breakpoint ) 
    {
        this.breakpoint = breakpoint;
        super( protocol, debugger );
    }

    override function execute()
    {
        var filePath:String = breakpoint.source.path;
        var line = breakpoint.line;
        var splited = filePath.split("\\");
	    var fname = splited.pop();
        debugger.send('break $fname:${line}');
    }

    override public function processDebuggerOutput(lines:Array<String>):Void
    {
        var breakpointData = lines[0];
        var r = ~/Breakpoint ([0-9]+): file ([0-9A-Za-z\.]+), line ([0-9]+)/;
        if (r.match(breakpointData))
        {
            breakpoint.id   = Std.parseInt(r.matched(1));
            breakpoint.source.name = r.matched(2);
            breakpoint.line = Std.parseInt(r.matched(3));
        }
        else
            trace( 'SetBreakpoint FAILED: [ $lines ]');

        done = true;
    }
}