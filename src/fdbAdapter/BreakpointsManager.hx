package fdbAdapter;

import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types.SetBreakpointsArguments;
import protocol.debug.Types.SetBreakpointsResponse;
import protocol.debug.Types.Breakpoint;
import fdbAdapter.commands.fdb.SetBreakpoint;

class BreakpointsManager {
    
    var context:Context;
    
    public function new(context:Context) {
        this.context = context;
    }

    public function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        trace("setBreakPointsRequest");
        trace( args );
        var resultIndex = 0;
        var commands:Array<SetBreakpoint> = [];
    
        var justAdded:Array<Breakpoint> = [];
        var commandDoneCallback = function() {
            resultIndex++;
            if (resultIndex >= commands.length) {
                response.success = true;
                response.body = {
                    breakpoints : justAdded
                };
                trace('send breakpoints result: $response' );
                context.protocol.sendResponse( response );
            }
        }        
        
        var source = new SourceImpl(args.source.name, args.source.path);
        var path = args.source.path;
        var breakpoints = [];
        var alreadySet = getAlreadySetMap(path, context.breakpoints);

        for (b in args.breakpoints) {
            if (alreadySet.exists(b.line)) {
                breakpoints.push( alreadySet.get(b.line));
            } 
            else {
                var result:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
                var command = new SetBreakpoint(context, result);
                justAdded.push(result);
                breakpoints.push(result);
                command.callback =  commandDoneCallback;
                context.debugger.queueCommand(command);
                commands.push(command);
            }
        }
        context.breakpoints.set( path, breakpoints);
    }

    function getAlreadySetMap(path:String, breakpoints:Map<String, Array<Breakpoint>>):Map<Int, Breakpoint> {
        var result = new Map<Int, Breakpoint>();
        if (breakpoints.exists(path)) {
            var addedForThisPath:Array<Breakpoint> = breakpoints.get(path);
            for (b in addedForThisPath) {
                result.set(b.line, b);
            }
        }
        return result;
    }
}