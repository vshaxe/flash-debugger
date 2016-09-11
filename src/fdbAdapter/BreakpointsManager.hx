package fdbAdapter;
import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types;
import fdbAdapter.commands.fdb.SetBreakpoint;
import fdbAdapter.FDBAdapter;


class BreakpointsManager
{
    var context:Context;
    
    public function new(context:Context)
    {
        this.context = context;
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
                context.protocol.sendResponse( response );
            }
        }        
        
        for (b in args.breakpoints)
        {
            var source = new SourceImpl(args.source.name, args.source.path);
            var path = args.source.path;
            if (!context.breakpoints.exists(path))
                context.breakpoints.set(path, []);
            var breakpoints = context.breakpoints.get(path);
            var result:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
            var command = new SetBreakpoint(context, result);
            justAdded.push(result);
            breakpoints.push(result);
            command.callback =  commandDoneCallback;
            context.debugger.queueCommand(command);
            commands.push(command);
        }
    }
}