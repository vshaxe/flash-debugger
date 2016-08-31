package fdbAdapter;
import js.node.Buffer;
import adapter.ProtocolServer;
import adapter.DebugSession;
import js.node.stream.Writable;
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