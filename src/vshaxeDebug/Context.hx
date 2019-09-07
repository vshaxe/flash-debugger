package vshaxeDebug;

import vscode.debugAdapter.Handles;
import vscode.debugAdapter.Protocol;
import vscode.debugAdapter.DebugSession.OutputEvent as OutputEventImpl;
import vscode.debugProtocol.DebugProtocol;
import vshaxeDebug.EDebuggerState.StateController;
import vshaxeDebug.EDebuggerState.EStateControlEvent;

class Context {
	public var variableHandles(default, null):Handles<String>;
	public var knownObjects(default, null):Map<Int, String>;
	public var sourcePath(default, default):String;
	public var fileNameToFullPathDict(default, default):Map<String, String>;
	public var breakpoints(default, null):Map<String, Array<Breakpoint>>;
	public var debugger(default, null):IDebugger;
	public var protocol(default, null):ProtocolServer;
	public var debuggerState(default, null):EDebuggerState;

	public function new(protocol:ProtocolServer, debugger:IDebugger) {
		this.protocol = protocol;
		this.debugger = debugger;

		debuggerState = WaitingGreeting;
		breakpoints = new Map<String, Array<Breakpoint>>();
		fileNameToFullPathDict = new Map<String, String>();
		variableHandles = new Handles<String>();
		knownObjects = new Map<Int, String>();
	}

	public function onEvent(event:EStateControlEvent) {
		debuggerState = StateController.onEvent(this, event);
	}

	public function sendToOutput(output:String, category:OutputEventCategory = Console) {
		protocol.sendEvent(new OutputEventImpl(output + "\n", category));
	}

	public function sendError(response:Response<Dynamic>, message:String):Void {
		response.success = false;
		response.message = message;
		protocol.sendResponse(response);
	}
}
