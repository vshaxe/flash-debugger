package fdbAdapter.commands.fdb;

import adapter.DebugSession;

class Start extends DebuggerCommand 
{
    override public function processDebuggerOutput(lines:Array<String>):Void
    {
        var firstLine = lines[0];
        if (firstLine == null)
            return;

        if (firstLine.substr(0,5) == "Adobe")
        {
            protocol.sendEvent( new InitializedEvent());
            done = true;
        }
        else
            trace( 'Start FAILED: [ $lines ]');
    }
}