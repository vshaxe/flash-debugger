package vshaxeDebug;

import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import vshaxeDebug.Types;
import vshaxeDebug.commands.BaseCommand;
import haxe.ds.Option;

typedef AdapterDependencies = {
	function createContext(program:String):Context;
	function getLaunchCommand(context:Context, response:LaunchResponse, args:ExtLaunchRequestArguments):BaseCommand<LaunchResponse, ExtLaunchRequestArguments>;
	function getAttachCommand(context:Context, response:AttachResponse, args:ExtAttachRequestArguments):Option<
		BaseCommand<AttachResponse, ExtAttachRequestArguments>>;
}

class BaseAdapter extends adapter.DebugSession {
	var debugger:IDebugger;
	var context:Context;
	var cmd:ICommandBuilder;
	var parser:IParser;
	var deps:AdapterDependencies;
	var terminated:Bool = false;

	function new(deps:AdapterDependencies) {
		super();
		this.deps = deps;
	}

	override function dispatchRequest(request:Request<Dynamic>) {
		traceJson(request);
		super.dispatchRequest(request);
	}

	override function sendResponse(response:protocol.debug.Response<Dynamic>) {
		trace('sendResponse: $response');
		super.sendResponse(response);
	}

	override function initializeRequest(response:InitializeResponse, args:InitializeRequestArguments) {
		response.body.supportsConfigurationDoneRequest = true;
		response.body.supportsEvaluateForHovers = true;
		response.body.supportsStepBack = false;
		this.sendResponse(response);
	}

	override function launchRequest(response:LaunchResponse, args:LaunchRequestArguments) {
		var customArgs:ExtLaunchRequestArguments = cast args;
		context = deps.createContext(customArgs.program);
		debugger = context.debugger;
		parser = context.debugger.parser;
		cmd = context.debugger.commandBuilder;
		if ((customArgs.receiveAdapterOutput != null) && (customArgs.receiveAdapterOutput)) {
			redirectTraceToDebugConsole(context);
		}
		var launchCommand:BaseCommand<LaunchResponse, LaunchRequestArguments> = deps.getLaunchCommand(context, response, customArgs);
		launchCommand.execute();
	}

	override function attachRequest(response:AttachResponse, args:AttachRequestArguments) {
		var customArgs:ExtLaunchRequestArguments = cast args;
		context = deps.createContext(customArgs.program);
		debugger = context.debugger;
		parser = context.debugger.parser;
		cmd = context.debugger.commandBuilder;
		if ((customArgs.receiveAdapterOutput != null) && (customArgs.receiveAdapterOutput)) {
			redirectTraceToDebugConsole(context);
		}
		var maybeAttachCommand:Option<BaseCommand<AttachResponse, AttachRequestArguments>> = deps.getAttachCommand(context, response, customArgs);
		switch (maybeAttachCommand) {
			case Some(attachCommand):
				attachCommand.execute();
			default:
				throw "adapter doesn't support attach";
		}
	}

	override function setBreakPointsRequest(response:SetBreakpointsResponse, args:SetBreakpointsArguments) {
		var command = new vshaxeDebug.commands.SetBreakpoints(context, response, args);
		command.execute();
	}

	override function configurationDoneRequest(response:ConfigurationDoneResponse, args:ConfigurationDoneArguments) {
		debugger.queueSend(cmd.continueCommand());
		context.onEvent(Continue);
		sendResponse(response);
	}

	override function threadsRequest(response:ThreadsResponse) {
		response.body = {
			threads: [new ThreadImpl(1, "thread 1")]
		};
		sendResponse(response);
	}

	override function stackTraceRequest(response:StackTraceResponse, args:StackTraceArguments) {
		var cmd = new vshaxeDebug.commands.StackTrace(context, response, args);
		cmd.execute();
	}

	override function scopesRequest(response:ScopesResponse, args:ScopesArguments) {
		var frameId:Int = args.frameId;
		var scopes:Array<Scope> = [
			new ScopeImpl("Locals", context.variableHandles.create('locals_$frameId'), false),
			new ScopeImpl("Members", context.variableHandles.create('members_$frameId'), false),
			new ScopeImpl("Globals", context.variableHandles.create('globals_$frameId'), true)
		];

		response.body = {
			scopes: cast scopes
		};
		this.sendResponse(response);
	}

	override function variablesRequest(response:VariablesResponse, args:VariablesArguments) {
		var command = new vshaxeDebug.commands.Variables(context, response, args);
		command.execute();
	}

	override function evaluateRequest(response:EvaluateResponse, args:EvaluateArguments) {
		if (context == null)
			return this.sendResponse(response);

		switch (context.debuggerState) {
			case Stopped(_, _):
				var command = new vshaxeDebug.commands.Evaluate(context, response, args);
				command.execute();

			default:
				this.sendResponse(response);
		}
	}

	override function stepInRequest(response:StepInResponse, args:StepInArguments) {
		stepRequest(cmd.stepIn(), response);
	}

	override function stepOutRequest(response:StepOutResponse, args:StepOutArguments) {
		stepRequest(cmd.stepOut(), response);
	}

	override function nextRequest(response:NextResponse, args:NextArguments) {
		stepRequest(cmd.next(), cast response);
	}

	function stepRequest<T>(cmd:String, response:protocol.debug.Response<T>) {
		debugger.queueSend(cmd, function(_):Bool {
			sendResponse(response);
			sendEvent(new StoppedEvent("step", 1));
			return true;
		});
	}

	override function continueRequest(response:ContinueResponse, args:ContinueArguments) {
		debugger.queueSend(cmd.continueCommand());
		sendResponse(response);
		context.onEvent(Continue);
	}

	override function pauseRequest(response:PauseResponse, args:PauseArguments) {
		debugger.queueSend(cmd.pause(), function(_):Bool {
			sendResponse(response);
			context.onEvent(Stop(StopReason.pause));
			return true;
		});
	}

	override function disconnectRequest(response:DisconnectResponse, args:DisconnectArguments) {
		if (terminated) {
			sendResponse(response);
			return;
		}
		debugger.queueSend(cmd.disconnect(), function(_):Bool {
			sendResponse(response);
			return true;
		});
	}

	function onPromptGot(lines:Array<String>) {
		switch (context.debuggerState) {
			case EDebuggerState.WaitingGreeting:
				if (parser.isGreetingMatched(lines)) {
					context.onEvent(GreetingReceived);
				} else
					trace('Start FAILED: [$lines]');

			case EDebuggerState.Running:
				if (parser.isStopOnBreakpointMatched(lines)) {
					context.onEvent(Stop(StopReason.breakpoint));
				} else if (parser.isStopOnExceptionMatched(lines)) {
					context.onEvent(Stop(StopReason.exception));
				}
			case _:
		}
	}

	function allOutputReceiver(string:String):Bool {
		var proceed:Bool = false;
		if (parser.isExitMatched(string)) {
			var event = new TerminatedEvent(false);
			traceJson(event);
			sendEvent(event);
			terminated = true;
			debugger.stop();
			return true;
		}

		switch (context.debuggerState) {
			case EDebuggerState.Running:
				var lines:Array<String> = parser.getTraces(string);
				for (line in lines) {
					context.sendToOutput(line);
					proceed = true;
				}
			default:
		}
		return proceed;
	}

	function traceJson<T>(value:T) {
		trace(haxe.Json.stringify(value));
	}

	function redirectTraceToDebugConsole(context:Context) {
		haxe.Log.trace = function(v, ?i) {
			context.sendToOutput('DebugAdapter: $v', OutputEventCategory.stdout);
		}
	}
}
