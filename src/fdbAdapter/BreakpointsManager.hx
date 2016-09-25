package fdbAdapter;

import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types.SetBreakpointsArguments;
import protocol.debug.Types.SetBreakpointsResponse;
import protocol.debug.Types.Breakpoint;
import fdbAdapter.commands.fdb.SetBreakpoint;
import fdbAdapter.commands.fdb.RemoveBreakpoint;
import fdbAdapter.commands.DebuggerCommand;

private class CommandsBatchContext {

    var waiting:Int = 0; 
    var got:Int = 0;
    var callback:Void -> Void;

    public function new(callback:Void -> Void) {
        this.callback = callback;
    }

    public function add(command:DebuggerCommand) {
        command.callback = onResponse;
        waiting++;
    }

    public function onResponse() {
        got++;
        if (waiting == got)
            callback();
    }
}

class BreakpointsManager {
    
    var context:Context;

    public function new(context:Context) {
        this.context = context;
    }

    public function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        trace("setBreakPointsRequest");
        trace( args );

        var source = new SourceImpl(args.source.name, args.source.path);
        var path = args.source.path;

        if (!context.breakpoints.exists(path)) {
            context.breakpoints.set(path, []);
        }      

        var breakpoints = context.breakpoints.get(path);
        var previouslySet = getAlreadySetMap(path, context.breakpoints);
        var batchContext = new CommandsBatchContext( commandDoneCallback.bind(path, response ) );

        for (b in args.breakpoints) {
            if (previouslySet.exists(b.line)) {
                previouslySet.remove(b.line);
            } 
            else {
                var breakpoint:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
                var cmd = addBreakpoint(breakpoint, breakpoints);
                batchContext.add(cmd);
                context.debugger.queueCommand(cmd);
            }
        }

        for (needToRemove in previouslySet) {
            var cmd = removeBreakpoint(needToRemove, breakpoints);
            batchContext.add(cmd);
            context.debugger.queueCommand(cmd);
        }
    }

    function addBreakpoint(breakpoint:Breakpoint, container:Array<Breakpoint>):DebuggerCommand {
        var command = new SetBreakpoint(context, breakpoint);
        container.push(breakpoint);
        return command;
    }

    function removeBreakpoint(breakpoint:Breakpoint, container:Array<Breakpoint>):DebuggerCommand {
        var command = new RemoveBreakpoint(context, breakpoint);
        container.remove(breakpoint);
        return command;
    }

    function commandDoneCallback(path:String, response:SetBreakpointsResponse) {
        var breakpoints:Array<Breakpoint> = context.breakpoints.get(path);
        var validated = [for (b in breakpoints) if (b.id > 0) b];
        context.breakpoints.set(path, validated);
        response.success = true;
        response.body = {
            breakpoints : validated
        };
        trace('send breakpoints result: $response' );
        context.protocol.sendResponse( response );
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