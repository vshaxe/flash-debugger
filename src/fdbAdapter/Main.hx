package fdbAdapter;
import adapter.DebugSession;
import js.node.Fs;
class Main
{
    public static function main() {
        FDBAdapter.setup( { fdbCmd : "D:\\flex_sdk_4.6\\bin\\fdb.exe"
                          , fdbCmdParams : []});
        DebugSession.run( FDBAdapter );
        setupTrace();
    }

    static function setupTrace() {
        Fs.writeFile('log.txt', "", 'utf8', function(e){});
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
        Fs.appendFile('log.txt', haxe.Json.stringify(input) + "\n", 'utf8', function(e){ });
    }
}