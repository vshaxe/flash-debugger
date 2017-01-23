package fdbAdapter;

import vshaxeDebug.Context;
import vshaxeDebug.IDebugger;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.EDebuggerState;
import vshaxeDebug.Types;
import protocol.debug.Types;
import adapter.DebugSession;
import adapter.DebugSession.Thread as ThreadImpl;
import adapter.DebugSession.Scope as ScopeImpl;
import js.node.Fs;

class Adapter extends vshaxeDebug.BaseAdapter {

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

    override function createContext(program:String):Context {
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

    override function processAttachRequest(response:AttachResponse, args:ExtAttachRequestArguments) {
        debugger.queueSend("run", function(_):Bool {
            context.sendToOutput('waiting..', OutputEventCategory.stdout);
            return true;
        });
    }

    override function processLaunchRequest(response:LaunchResponse, args:ExtLaunchRequestArguments) {
        var command = new fdbAdapter.commands.Launch(context, response, args);
        command.execute();
    }
}
