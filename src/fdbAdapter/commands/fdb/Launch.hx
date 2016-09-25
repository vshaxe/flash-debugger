package fdbAdapter.commands.fdb;
import protocol.debug.Types.LaunchResponse;
import adapter.ProtocolServer;

typedef FDBLaunchRequestArguments =
{
   > protocol.debug.Types.LaunchRequestArguments,
    var runPath:String;
    var runCommand:String;
    var sourcePath:String;
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
        var program = args.runPath + "/" + args.runCommand;
        debugger.send('run $program');
    }
    
    override public function processDebuggerOutput(lines:Array<String>) {
        var matchingOutputLine = lines[lines.length - 1];
        if (matchSWFConnected( matchingOutputLine ))
        {
            protocol.sendResponse( response );
            setDone();
        }
        else
            trace( 'Launch FAILED: [ $lines ]');
    }

    function matchSWFConnected(data:String):Bool {
        return 
            if (data == null)
                false;
            else
                (data.substr(0,5) == "[SWF]");
    }
}
