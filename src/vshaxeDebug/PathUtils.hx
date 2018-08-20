package vshaxeDebug;

import js.node.Fs;
import js.node.Path;
import js.node.ChildProcess;

class PathUtils {
	public static function normalize(path:String):String {
		path = StringTools.replace(path, "\\", "/");

		if (~/^[a-zA-Z]:\//.match(path)) {
			path = '/' + path;
		}
		path = Path.normalize(path); // use node's normalize to remove '<dir>/..' etc.
		path = StringTools.replace(path, "\\", "/");
		return path;
	}

	public static function isAbsolutePath(path:String):Bool {
		var result:Bool = false;
		if (path != "") {
			if (path.charAt(0) == '/') {
				result = true;
			}
			if (~/^[a-zA-Z]:[\\\/]/.match(path)) {
				result = true;
			}
		}
		return result;
	}

	public static function isOnPath(program:String):Bool {
		if (js.Node.process.platform == "win32") {
			var WHERE = "C:\\Windows\\System32\\where.exe";
			try {
				if (Fs.existsSync(WHERE)) {
					ChildProcess.execSync('${WHERE} ${program}');
				} else {
					// do not report error if 'where' doesn't exist
				}
				return true;
			} catch (e:Dynamic) {
				// ignore
			}
		} else {
			var WHICH = '/usr/bin/which';
			try {
				if (Fs.existsSync(WHICH)) {
					ChildProcess.execSync('${WHICH} \'${program}\'');
				} else {
					// do not report error if 'which' doesn't exist
				}
				return true;
			} catch (e:Dynamic) {}
		}
		return false;
	}

	function normalizeDriveLetter(path:String):String {
		var regex = ~/^([A-Z])(:[\\\/].*)$/;
		if (regex.match(path)) {
			var drive = regex.matched(1);
			var tail = regex.matched(2);
			path = drive.toLowerCase() + tail;
		}
		return path;
	}
}
