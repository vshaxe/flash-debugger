package fdbAdapter;
import js.node.Buffer;

class FDBCommand
{
    // these are used for the queue
    public var prev:DisplayRequest;
    public var next:DisplayRequest;

    var token:CancellationToken;
    var args:Array<String>;
    var stdin:String;
    var callback:String->Void;
    var errback:String->Void;

    public function new() 
    {

    }

    public function prepareBody():Buffer
    {

    }

    public function processResult(data:String)
    {

    }
}