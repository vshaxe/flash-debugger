package vshaxeDebug;

import adapter.DebugSession.Breakpoint as BreakpointImpl;
import adapter.DebugSession.Source as SourceImpl;
import protocol.debug.Types.SetBreakpointsArguments;
import protocol.debug.Types.SetBreakpointsResponse;
import protocol.debug.Types.Breakpoint;
import vshaxeDebug.DebuggerCommand;

private class CommandsBatch {

    var waiting:Int = 0; 
    var got:Int = 0;
    var callback:Void -> Void;
    var debugger:IDebugger;

    public function new(debugger:IDebugger, callback:Void -> Void) {
        this.debugger = debugger;
        this.callback = callback;
    }

    public function add(command:DebuggerCommand) {
        waiting++;
        command.callback = onResponse;
        debugger.queueCommand(command);
    }

    public function onResponse() {
        got++;
        checkIsDone();
    }

    public function checkIsDone() {
        if (waiting == got)
            callback();
    }
}

typedef BreakpointsCommandsFactory = {
    var stopForBreakpointsSetting :  Context -> DebuggerCommand;
    var continueAfterBreakpointsSet : Context -> DebuggerCommand;
    var setBreakpoint : Context -> Breakpoint -> DebuggerCommand;
    var removeBreakpoint : Context -> Breakpoint -> DebuggerCommand;
}

class BreakpointsManager {
    
    var context:Context;
    var commands:BreakpointsCommandsFactory;

    public function new(context:Context, commandsFactory:BreakpointsCommandsFactory) {
        this.context = context;
        this.commands = commandsFactory;
    }

    public function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
        var source = new SourceImpl(args.source.name, args.source.path);
        var pathKey = getKey(args.source.name);

        if (!context.breakpoints.exists(pathKey)) {
            context.breakpoints.set(pathKey, []);
        }      

        var breakpoints = context.breakpoints.get(pathKey);
        var previouslySet = getAlreadySetMap(pathKey, context.breakpoints);
        var batch = new CommandsBatch(context.debugger, commandDoneCallback.bind(pathKey, response ));

        switch (context.debuggerState) {
            case EDebuggerState.Running:
                batch.add(commands.stopForBreakpointsSetting(context));
            default:
        }

        for (b in args.breakpoints) {
            if (previouslySet.exists(b.line)) {
                previouslySet.remove(b.line);
            } 
            else {
                var breakpoint:Breakpoint = new BreakpointImpl(true, b.line, 0, source);
                batch.add(addBreakpoint(breakpoint, breakpoints));
            }
        }

        for (needToRemove in previouslySet) {
            batch.add(removeBreakpoint(needToRemove, breakpoints));
        }

        switch (context.debuggerState) {
            case EDebuggerState.Running:
                batch.add(commands.continueAfterBreakpointsSet(context));
            default:
        }
        batch.checkIsDone();
    }
    
    function addBreakpoint(breakpoint:Breakpoint, container:Array<Breakpoint>):DebuggerCommand {
        var command = commands.setBreakpoint(context, breakpoint);
        container.push(breakpoint);
        return command;
    }

    function removeBreakpoint(breakpoint:Breakpoint, container:Array<Breakpoint>):DebuggerCommand {
        var command = commands.removeBreakpoint(context, breakpoint);
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

    function getKey(path:String):String {
        var result = StringTools.replace(path, "\\", "/");
        return result;
    }
}
