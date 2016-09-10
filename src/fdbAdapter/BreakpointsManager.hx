package fdbAdapter;
import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types;
import fdbAdapter.commands.fdb.SetBreakpoint;
import fdbAdapter.FDBAdapter;


class BreakpointsManager
{
    var breakpoints:Array<Breakpoint> = [];
    var protocol:FDBAdapter;
    var debugger:IDebugger;

    public function new(protocol:FDBAdapter, debugger:IDebugger)
    {
        this.protocol = protocol;
        this.debugger = debugger;
    }

    public function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments):Void
    {
        trace("setBreakPointsRequest");
        trace( args );
        var resultIndex = 0;
        var commands:Array<SetBreakpoint> = [];
    
        var justAdded:Array<Breakpoint> = [];
        var commandDoneCallback = function()
        {
            resultIndex++;
            if (resultIndex >= commands.length)
            {
                response.success = true;
                response.body = {
                    breakpoints : justAdded
                };
                trace('send breakpoints result: $response' );
                protocol.sendResponse( response );
            }
        }        
        
        for (b in args.breakpoints)
        {
            var source = new SourceImpl(args.source.name, args.source.path);
            var result:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
            var command = new SetBreakpoint(protocol, debugger, result);
            justAdded.push(result);
            breakpoints.push(result);
            command.callback =  commandDoneCallback;
            debugger.queueCommand(command);
            commands.push(command);
        }
    }
}