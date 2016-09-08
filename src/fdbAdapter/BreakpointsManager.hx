package fdbAdapter;
import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types;
import fdbAdapter.FDBCommand;
import fdbAdapter.FDBAdapter;

class BreakpointsManager
{
    var breakpoints:Array<Breakpoint> = [];
    var protocol:FDBAdapter;

    public function new(protocol:FDBAdapter)
    {
        this.protocol = protocol;
    }

    public function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments):Void
    {
        trace("setBreakPointsRequest");
        trace( args );
        var resultIndex = 0;
        var commands:Array<SetBreakpointCommand> = [];
    
        var justAdded:Array<Breakpoint> = [];
        var commandDoneCallback = function()
        {
            var result = commands[resultIndex].result;
            trace( result );
            var source = new SourceImpl(args.source.name, args.source.path);
            var b:Breakpoint = new BreakpointImpl(true, result.line, 0, source);
            b.id = result.id;
            breakpoints.push( b );
            justAdded.push( b );
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
            var command = new SetBreakpointCommand(protocol, args.source.path, b.line);
            command.callback =  commandDoneCallback;
            protocol.queueCommand(command);
            commands.push(command);
        }
    }
}