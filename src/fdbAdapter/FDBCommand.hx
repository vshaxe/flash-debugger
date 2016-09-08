package fdbAdapter;
import js.node.Buffer;
import adapter.ProtocolServer;
import adapter.DebugSession;
import js.node.stream.Writable;
import protocol.debug.Types as DebugProtocol;
import js.node.child_process.ChildProcess;

class FDBCommand
{
    // these are used for the queue
    public var prev:FDBCommand;
    public var next:FDBCommand;
    public var done(get,set):Bool;
    public var callback(never,set):Void->Void;

    var command:String;
    var protocol:ProtocolServer;
    

    public function new(protocol:ProtocolServer) 
    {
        this.protocol = protocol;
    }

    public function execute(proc:ChildProcess):Void
    {
    
    }

    public function processFDBOutput(proc:ChildProcess, lines:Array<String>):Void
    {
        
    }

    var _callback:Void->Void = function() {};
    var _done = false;

    function get_done():Bool
        return _done;
    function set_done(val:Bool):Bool
    {
        if (val)
            _callback();
        return _done = val;
    }

    function set_callback(callback:Void->Void):Void->Void
    {
        _callback = callback;
        return _callback;
    }
}

class StartFDBCommand extends FDBCommand 
{
    override function execute(proc:ChildProcess)
    {
        //proc.stdin.write( "run\n" );
    }

    override public function processFDBOutput(proc:ChildProcess, lines:Array<String>):Void
    {
        if (state0match(lines[0]))
        {
            protocol.sendEvent( new InitializedEvent());
            done = true;
        }
        else
        {
            trace( "StartFDB failed");
        }
    }

    function state0match(data:String):Bool
    {
        return (data.substr(0,5) == "Adobe");
    }
}

typedef FDBLaunchRequestArguments =
{
   > protocol.debug.Types.LaunchRequestArguments,
    var runPath:String;
    var runCommand:String;
} 

class LaunchCommand extends FDBCommand
{
    var args:FDBLaunchRequestArguments;
    var response:protocol.debug.Types.LaunchResponse;

    public function new(protocol:ProtocolServer, response:protocol.debug.Types.LaunchResponse, args:FDBLaunchRequestArguments)
    {
        this.args = args;
        this.response = response;
        super(protocol);
    }

    override function execute(proc:ChildProcess)
    {
        trace( "LaunchCommand execute" );
        var program = args.runPath + "/" + args.runCommand;
        proc.stdin.write('run $program\n');
    }

     override public function processFDBOutput(proc:ChildProcess, lines:Array<String>):Void
    {
        trace('LaunchCommand processResult: $lines');
        var matchingOutputLine = lines[lines.length - 1];
        if (matchSWFConnected( matchingOutputLine ))
        {
            protocol.sendResponse( response );
            done = true;
        }
        else
        {
            trace( "something wrong");
        }
    }

     function matchSWFConnected(data:String):Bool
    {
        if (data == null)
            return false;

        return (data.substr(0,5) == "[SWF]");
    }
}

class SetBreakpointCommand extends FDBCommand
{
    public var result(default, null):Null<{id:Int, file:String, line:Int}>;
    var sourcePath:String;
    var line:Int;

    public function new(protocol:ProtocolServer, sourcePath:String, line:Int ) 
    {
        this.sourcePath = sourcePath;
        this.line = line;
        super( protocol );
    }

    override function execute(proc:ChildProcess)
    {
        var filePath:String = sourcePath;
        var splited = filePath.split("\\");
	    var fname = splited.pop();
        proc.stdin.write('break $fname:${line}\n');
    }

    
    override public function processFDBOutput(proc:ChildProcess, lines:Array<String>):Void
    {
        var breakpointData = lines[0];
        var r = ~/Breakpoint ([0-9]+): file ([0-9A-Za-z\.]+), line ([0-9]+)/;
        if (r.match(breakpointData))
        {
            result = {
                id : Std.parseInt(r.matched(1))
                , file : r.matched(2)
                , line : Std.parseInt(r.matched(3))
            };
        }
        done = true;
    }
}

class ContinueCommand extends FDBCommand
{
    public function new(protocol:ProtocolServer) 
    {
        super( protocol );
    }

    override function execute(proc:ChildProcess)
    {
        proc.stdin.write('c\n');
        done = true;
    }

    override public function processFDBOutput(proc:ChildProcess, lines:Array<String>):Void
    {
        trace( 'Continue result: $lines' );
        //proc.sendResponse(response);

        //[[trace] MainScreenView.hx:24: Play!,Breakpoint 1, GameRound() at GameRound.hx:18, 18            game = gameFactory(reportAnswer);]
        done = true;
    }
}