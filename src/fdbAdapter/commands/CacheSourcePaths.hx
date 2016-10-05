package fdbAdapter.commands;

import vshaxeDebug.DebuggerCommand;

class CacheSourcePaths extends DebuggerCommand {
    
    override function execute() {
        debugger.send("show files");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var rRow = ~/^([0-9]+) (.+), ([a-zA-Z0-9:.]+)$/;
        for (l in lines) {
            if (rRow.match(l)) {
                context.fileNameToFullPathDict.set(rRow.matched(3), rRow.matched(2));                
            }
        }
        setDone();
    }
}
