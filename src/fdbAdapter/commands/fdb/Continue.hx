package fdbAdapter.commands.fdb;

class Continue extends DebuggerCommand
{
    override function execute()
    {
        debugger.send('c');
        done = true;
    }
}