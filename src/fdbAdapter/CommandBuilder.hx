package fdbAdapter;

class CommandBuilder implements vshaxeDebug.ICommandBuilder {
	public function new() {}

	public function launch(program:String):String
		return 'run $program';

	public function frameUp():String
		return "up";

	public function frameDown():String
		return "down";

	public function stepIn():String
		return "step";

	public function stepOut():String
		return "finish";

	public function next():String
		return "next";

	public function continueCommand():String
		return "continue";

	public function pause():String
		return "\ny";

	public function stackTrace():String
		return "bt";

	public function addBreakpoint(fileName:String, filePath:String, line:Int):String
		return 'break $fileName:${line}';

	public function removeBreakpoint(fileName:String, filePath:String, line:Int):String
		return 'clear $fileName:${line}';

	public function printLocalVariables():String
		return "info locals";

	public function printFunctionArguments():String
		return "info arguments";

	public function printGlobalVariables():String
		return "info global";

	public function printObjectProperties(?objectName:String):String
		return 'print $objectName.';

	public function printMembers():String
		return "print this.";

	public function showFiles():String
		return "show files";

	public function evaluate(expr:String):String
		return 'print $expr';

	public function disconnect():String
		return "kill\ny\nquit";
}
