package test;

import utest.Runner;
import utest.ui.Report;

class TestAll {
	static public function main() {
		var runner = new Runner();
		runner.addCase(new AutomatedTests());
		Report.create(runner);
		runner.run();
	}
}
