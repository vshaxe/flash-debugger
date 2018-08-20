package test;

import utest.Assert;
import testSupport.DebugClient;
import js.Promise;

class AutomatedTests {
	var dc:DebugClient;

	public function new() {}

	@:keep public function setup() {
		dc = new DebugClient('node', 'bin/adapter.js', 'node');
		var p = dc.start();
	}

	public function testTerminated() {
		var done = Assert.createAsync(10000);
		var p = Promise.all([
			// dc.initializeRequest()
			// , dc.waitForEvent("initialized")
			dc.hitBreakpoint({}, {verified: true, path: "Test.hx", line: 10}, {verified: true, path: "Test.hx", line: 10})
		]).then(function(r) {
			trace(r);
			Assert.notNull(r);
			done();
		}).catchError(function(e) {
			trace(e);
			done();
		});
	}

	@:keep public function teardown() {
		dc.stop();
	}
}
