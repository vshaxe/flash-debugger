package fdbAdapter;

import vshaxeDebug.Context;
import vshaxeDebug.IDebugger;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.EDebuggerState;
import vshaxeDebug.Types;
import vshaxeDebug.BaseAdapter;
import vshaxeDebug.commands.BaseCommand;
import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import js.node.Fs;
import haxe.ds.Option;

class Adapter extends BaseAdapter {

    static var logPath:String;

    static function main() {
        setupTrace();
        DebugSession.run(Adapter);
    }

    static function setupTrace() {
        logPath = js.Node.__dirname + "/../fdb_log.txt";
        Fs.writeFile(logPath, "", "utf8", function(e){});
        haxe.Log.trace = function(v, ?i) {
            var r = [Std.string(v)];
            Log({type: "INFO", message: r.join(" ")});
        }
    }

    static function Log(input:{type:String, message:String}) {
        Fs.appendFile(logPath, haxe.Json.stringify(input) + "\n", 'utf8', function(e){ });
    }

    public function new() {
        var deps:AdapterDependencies = {
            createContext : createContext,
            getLaunchCommand : getLaunchCommand,
            getAttachCommand : getAttachCommand
        };
        super(deps);
    }

    function getLaunchCommand(context:Context, response:LaunchResponse, args:ExtLaunchRequestArguments):BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {
        return new fdbAdapter.commands.Launch(context, response, args);
    }

    function getAttachCommand(context:Context,
                              response:AttachResponse,
                              args:ExtAttachRequestArguments):Option<BaseCommand<AttachResponse, ExtAttachRequestArguments>> {
                                  
        var command:BaseCommand<AttachResponse, ExtAttachRequestArguments> = new fdbAdapter.commands.Attach(context, response, args);
        return Some(command);
    }

    function createContext(program:String):Context {
        var scriptPath = js.Node.__dirname;
        var commandBuilder:vshaxeDebug.ICommandBuilder = new CommandBuilder();
        var parser:vshaxeDebug.IParser = new Parser();
        var cliAdapterConfig = {
            cmd:"java",
            cmdParams:["-Duser.language=en", "-jar", '$scriptPath/../fdb/fdb.jar'],
            onPromptGot:onPromptGot,
            allOutputReceiver:allOutputReceiver,
            commandBuilder : commandBuilder,
            parser : parser
        };

        debugger = new CLIAdapter(cliAdapterConfig);
        debugger.start();
        return new Context(this, debugger);
    }
}
