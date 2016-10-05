package vshaxeDebug.types;

enum VarRequestType {
    Locals(frameId:Int);
    Global(frameId:Int);
    Closure(frameId:Int);
    ObjectDetails(name:String);
}
