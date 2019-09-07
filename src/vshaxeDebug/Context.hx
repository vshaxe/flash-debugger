package vshaxeDebug;

import vscode.debugAdapter.Handles;
import vscode.debugAdapter.Protocol;
import vscode.debugAdapter.DebugSession.OutputEvent as OutputEventImpl;
import vscode.debugProtocol.DebugProtocol;
import vshaxeDebug.DebuggerState.StateController;
import vshaxeDebug.DebuggerState.StateControlEvent;

class Context {
	public final debugger:IDebugger;
	public final protocol:ProtocolServer;

	public final breakpoints:Map<String, Array<Breakpoint>>;
	public final fileNameToFullPathDict:Map<String, String>;
	public final variableHandles:Handles<String>;
	public final knownObjects:Map<Int, String>;

	public var debuggerState(default, null):DebuggerState;

	public function new(protocol:ProtocolServer, debugger:IDebugger) {
		this.protocol = protocol;
		this.debugger = debugger;

		breakpoints = new Map<String, Array<Breakpoint>>();
		fileNameToFullPathDict = new Map<String, String>();
		variableHandles = new Handles<String>();
		knownObjects = new Map<Int, String>();
		debuggerState = WaitingGreeting;
	}

	public function onEvent(event:StateControlEvent) {
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
