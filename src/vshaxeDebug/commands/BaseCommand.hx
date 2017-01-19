package vshaxeDebug.commands;

class BaseCommand<ResponseType, ArgsType> {

    var context:Context;
    var debugger:IDebugger;
    var response:ResponseType;
    var args:ArgsType;
    var t:ITranslator;

    public function new(context:Context, response:ResponseType, args:ArgsType) {
        this.context = context;
        this.debugger = context.debugger;
        this.response = response;
        this.args = args;
        this.t = debugger.translator;
    }

    public function execute() {}
}