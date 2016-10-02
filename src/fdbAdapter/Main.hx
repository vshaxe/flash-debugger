package fdbAdapter;
import adapter.DebugSession;
import js.node.Fs;

class Main
{
    static var scriptPath:String;
    static function main() {
        setupTrace();
        scriptPath = js.Node.__dirname;
        FDBAdapter.setup( {fdbConfig : { 
            fdbCmd : "java"
            , fdbCmdParams : ["-Duser.language=en", "-jar", '$scriptPath/fdb/fdb.jar']
        }});
        DebugSession.run( FDBAdapter );
    }

    static function setupTrace() {
        Fs.writeFile('$scriptPath/../log.txt', "", 'utf8', function(e){});
        haxe.Log.trace = function(v, ?i) {
            var r = [Std.string(v)];
            if (i != null && i.customParams != null) {
                for (v in i.customParams)
                    r.push(Std.string(v));
            }
            Log({type: "INFO", message: r.join(" ")});
        }
    }

    static function Log(input:{type:String, message:String}) {
        Fs.appendFile('$scriptPath/../log.txt', haxe.Json.stringify(input) + "\n", 'utf8', function(e){ });
    }
}
