package fdbAdapter.commands;

import vshaxeDebug.Context;
import protocol.debug.Types.LaunchResponse;
import protocol.debug.Types.OutputEventCategory;


typedef FDBAttachRequestArguments =
{
   > protocol.debug.Types.LaunchRequestArguments,
   @:optional var receiveAdapterOutput:Bool;
}

class Attach extends Launch {
    
    public function new(context:Context, response:LaunchResponse, args:FDBAttachRequestArguments) {
        super(context, response, cast args);
    }

    override function execute() {
        debugger.send('run');
        context.sendToOutput('waiting..', OutputEventCategory.stdout);
    }
}
