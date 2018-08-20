package vshaxeDebug;

class CommandsBatch {
	var waiting:Int;
	var got:Int;
	var callback:Void->Void;
	var debugger:IDebugger;

	public function new(debugger:IDebugger, callback:Void->Void) {
		this.debugger = debugger;
		this.callback = callback;
		waiting = got = 0;
	}

	public function add(command:String, ?callback:Array<String>->Bool) {
		if (callback != null) {
			waiting++;
		}
		debugger.queueSend(command, wrap(callback));
	}

	public function onResponse() {
		got++;
		checkIsDone();
	}

	public function checkIsDone() {
		if (waiting == got) {
			callback();
		}
	}

	function wrap(?callback:Array<String>->Bool):Array<String>->Bool {
		var wrapper = callback;
		if (callback != null) {
			wrapper = function(output:Array<String>):Bool {
				var result = callback(output);
				if (result) {
					got++;
					checkIsDone();
				}
				return result;
			}
		}
		return wrapper;
	}
}
