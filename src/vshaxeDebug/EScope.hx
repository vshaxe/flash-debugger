package vshaxeDebug;

@:enum 
abstract ScopeLocalsType(Int) {
    var NotSpecified = 1;
    var FunctionArguments = 2;
    var LocalVariables = 3;
}

enum EScope {
    Locals(frameId:Int, type:ScopeLocalsType);
    Global(frameId:Int);
    Closure(frameId:Int);
    ObjectDetails(id:Int, name:String);
}