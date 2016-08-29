package fdbAdapter;
import adapter.DebugSession;
import js.node.Fs;
class Main
{
    public static function main() {
        DebugSession.run( FDBAdapter );
        setupTrace();
    }

    static function setupTrace() {
        haxe.Log.trace = function(v, ?i) {
            var r = [Std.string(v)];
            if (i != null && i.customParams != null) {
                for (v in i.customParams)
                    r.push(Std.string(v));
            }
            Log({type: "INFO", message: r.join(" ")});
        }
    }

    static function Log( input:{type:String, message:String} ):Void
    {
        Fs.writeFile('log.txt', haxe.Json.stringify(input), 'utf8', function(e){ });
    }
}