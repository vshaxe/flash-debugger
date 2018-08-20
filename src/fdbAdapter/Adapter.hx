package fdbAdapter;

import vshaxeDebug.Context;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.Types;
import vshaxeDebug.BaseAdapter;
import vshaxeDebug.ICommandBuilder;
import vshaxeDebug.IParser;
import vshaxeDebug.PlatformParameters;
import vshaxeDebug.commands.BaseCommand;
import protocol.debug.Types;
import adapter.DebugSession;
import js.node.Fs;
import haxe.ds.Option;
import haxe.io.Path;

class Adapter extends BaseAdapter {
	static var logPath:String;

	static function main() {
		setupTrace();
		DebugSession.run(Adapter);
	}

	static function setupTrace() {
		logPath = js.Node.__dirname + "/../fdb_log.txt";
		Fs.writeFile(logPath, "", "utf8", function(e) {});
		haxe.Log.trace = function(v, ?i) {
			var r = [Std.string(v)];
			Log({type: "INFO", message: r.join(" ")});
		}
	}

	static function Log(input:{type:String, message:String}) {
		Fs.appendFile(logPath, haxe.Json.stringify(input) + "\n", 'utf8', function(e) {});
	}

	public function new() {
		var deps:AdapterDependencies = {
			createContext: createContext,
			getLaunchCommand: getLaunchCommand,
			getAttachCommand: getAttachCommand
		};
		super(deps);
	}

	function getLaunchCommand(context:Context, response:LaunchResponse, args:ExtLaunchRequestArguments):BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {
		return new fdbAdapter.commands.Launch(context, response, args);
	}

	function getAttachCommand(context:Context, response:AttachResponse, args:ExtAttachRequestArguments):Option<
		BaseCommand<AttachResponse, ExtAttachRequestArguments>> {
		var command:BaseCommand<AttachResponse, ExtAttachRequestArguments> = new fdbAdapter.commands.Attach(context, response, args);
		return Some(command);
	}

	function createContext(program:String):Context {
		var scriptPath = js.Node.__dirname;
		var commandBuilder:ICommandBuilder = new CommandBuilder();
		var eolSign = PlatformParameters.getEndOfLineSign();
		var parser:IParser = new Parser(eolSign);
		var cliAdapterConfig = {
			cmd: resolveJavaPath(),
			cmdParams: ["-Duser.language=en", "-jar", '$scriptPath/../fdb/fdb.jar'],
			onPromptGot: onPromptGot,
			onError: function(error) {
				return "Could not start fdb. Make sure that PATH contains the Java executable or JAVA_HOME is set correctly.";
			},
			allOutputReceiver: allOutputReceiver,
			commandBuilder: commandBuilder,
			parser: parser
		};

		debugger = new CLIAdapter(cliAdapterConfig);
		debugger.start();
		return new Context(this, debugger);
	}

	function resolveJavaPath():String {
		var path = "java";
		var javaHome = Sys.getEnv("JAVA_HOME");
		if (javaHome != null) {
			path = Path.join([javaHome, "bin/java"]);
		}
		return path;
	}
}
