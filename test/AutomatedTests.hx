package test;
import utest.Assert;
import testSupport.DebugClient;
import js.Promise;

class AutomatedTests
{
    var dc:DebugClient;
    public function new()
    {

    }

    @:keep public function setup() 
    {
       dc = new DebugClient('node', './bin/adapter.js', 'node');
	   dc.start();
    }

    public function testTerminated() 
    {
        var done = Assert.createAsync(300);
        var p = Promise.all([
            dc.configurationSequence(),
            dc.launch({ program: "test/sample/sample.swf" }),
            dc.waitForEvent('terminated')
        ]);
        p.then(function(r) {
            trace( r );
            Assert.notNull(r);
            done();
        });
    }

    @:keep public function teardown() 
    {
       dc.stop();
    }
} 