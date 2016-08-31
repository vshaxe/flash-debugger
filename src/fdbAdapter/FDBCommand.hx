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

    var command:String;
    var protocol:ProtocolServer;
    var callback:String->Void;
    var errback:String->Void;

    public function new(protocol:ProtocolServer) 
    {
        this.protocol = protocol;
    }

    public function execute(proc:ChildProcess):Void
    {
    
    }

    public function processResult(data:String):Void
    {
        protocol.sendEvent( new InitializedEvent());
    }
}

class StartFDBCommand extends FDBCommand 
{

    override function execute(proc:ChildProcess)
    {

    }

    override public function processResult(data:String):Void
    {
        trace( data );
        protocol.sendEvent( new InitializedEvent());
    }

}

class SetBreakpointCommand extends FDBCommand
{
    var args:protocol.debug.Types.SetBreakpointsArguments;
    var index:Int = 0;
    public function new(protocol:ProtocolServer, args:protocol.debug.Types.SetBreakpointsArguments, breakpointIndex:Int) 
    {
        this.args = args;
        this.index = breakpointIndex;
        super( protocol );

    }

    override function execute(proc:ChildProcess)
    {

        var filePath:String = args.source.path;        
        proc.stdin.write('break $filePath:${args.breakpoints[index].line}\n');
    }

    override public function processResult(data:String):Void
    {
        trace('SetBreakpointCommand processResult: $data');
        protocol.sendEvent( new InitializedEvent());
    }
}