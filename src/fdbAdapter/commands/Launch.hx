package fdbAdapter.commands;

import vshaxeDebug.Context;
import vshaxeDebug.PathUtils;
import vshaxeDebug.DebuggerCommand;
import protocol.debug.Types.LaunchResponse;
import protocol.debug.Types.OutputEventCategory;
import js.node.Fs;
import js.node.Buffer;
import js.node.ChildProcess;

@:enum
abstract RequestType(String) from String
{
    var launch = "launch";
    var compileAndLaunch = "compileAndLaunch";
}

typedef FDBLaunchRequestArguments =
{
   > protocol.debug.Types.LaunchRequestArguments,
   var program:String;
   var request:RequestType;
   @:optional var compileCommand:String;
   @:optional var compilePath:String;
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
        if (args.request == RequestType.compileAndLaunch) {
            doCompile(doLaunch);
        }
        else {
            doLaunch();
        }
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

    function doCompile(callback:Void -> Void) {
        var compileCommand:Null<String> = args.compileCommand;
        var compilePath:Null<String> = args.compilePath;
        try {
            context.sendToOutput('compiling: $compileCommand');
            var compileResult:Buffer = ChildProcess.execSync('$compileCommand', {cwd : compilePath});
            context.sendToOutput("compile ok");
            callback();
        }
        catch (e:Dynamic) {
            response.success = false;
            response.message = 'Cannot compile $compileCommand on PATH $compilePath';
            protocol.sendResponse(response);
        }
    }

    function doLaunch() {
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

    function matchSWFConnected(data:String):Bool {
        return 
            if (data == null)
                false;
            else
                (data.substr(0,5) == "[SWF]");
    }
}
