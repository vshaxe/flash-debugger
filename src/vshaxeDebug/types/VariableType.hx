package vshaxeDebug.types;

@:enum
abstract VariableType(String) to String {

    var Object = "Object";
    var Int = "Int";
    var Float = "Float";
    var String = "String";
    var Bool = "Bool";
    var Unknown = "Unknown";
}
