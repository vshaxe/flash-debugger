package fdbAdapter.commands.fdb;
import protocol.debug.Types.LaunchResponse;
import protocol.debug.Types;
import adapter.ProtocolServer;
import js.node.Fs;

typedef FDBLaunchRequestArguments =
{
   > protocol.debug.Types.LaunchRequestArguments,
   var program:String;
} 

class Launch extends DebuggerCommand {

    var args:FDBLaunchRequestArguments;
    var response:LaunchResponse;

    public function new(context:Context, response:LaunchResponse, args:FDBLaunchRequestArguments) {
        this.args = args;
        this.response = response;
        super(context);
    }

    override function execute() {
        var program = args.program;

        if (!PathUtils.isAbsolutePath(program)) {
			if (!PathUtils.isOnPath(program)) {
                response.success = false;
                response.message = 'Cannot find runtime $program on PATH.';
                protocol.sendResponse(response);
				return;
			}
        } 
        else if (!Fs.existsSync(program)) {
            response.success = false;
            response.message = 'Cannot find $program';
			protocol.sendResponse(response);
			return;
        }

        debugger.send('run $program');
        context.sendToOutput('running $program', OutputEventCategory.stdout);
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var matchingOutputLine = lines[lines.length - 1];
        for (line in lines) {
            if (matchSWFConnected(line)) {
                protocol.sendResponse( response );
                context.sendToOutput("swf connected", OutputEventCategory.stdout);
                setDone();
            }
        }
    }

    function matchSWFConnected(data:String):Bool {
        return 
            if (data == null)
                false;
            else
                (data.substr(0,5) == "[SWF]");
    }
}
