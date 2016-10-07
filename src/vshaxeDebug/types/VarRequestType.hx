package vshaxeDebug.types;

enum VarRequestType {
    Locals(frameId:Int);
    Arguments(frameId:Int);
    Global(frameId:Int);
    Closure(frameId:Int);
    ObjectDetails(id:Int, name:String);
}
