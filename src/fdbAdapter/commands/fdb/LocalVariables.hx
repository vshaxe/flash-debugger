package fdbAdapter.commands.fdb;

import protocol.debug.Types.VariablesResponse;

class LocalVariables extends DebuggerCommand {

    var response:VariablesResponse;
    public function new(context:Context, response:VariablesResponse) {
        this.response = response;
        super(context);
    }

    override public function execute() {
        debugger.send("info locals");
    }

    override public function processDebuggerOutput(lines:Array<String>) {
        var variables = [];
        var rObject = ~/(.*) = \[Object ([0-9]+), class='(.*)'\]/;
        trace('LOCALS:  $lines');
        for (l in lines) {
            if (rObject.match(l)) {
                variables.push({
                    name: rObject.matched(1),
                    type: rObject.matched(3),
                    value: '${rObject.matched(3)} [${rObject.matched(2)}]',
                    variablesReference: context.variableHandles.create('object_${rObject.matched(1)}')
			    });
            }
        }
        response.body = {
            variables : variables
        };
        protocol.sendResponse(response);
        setDone();
    }
}
