package vshaxeDebug;

class CommandsBatch {

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
