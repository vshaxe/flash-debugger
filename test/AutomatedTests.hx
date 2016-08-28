package test;
import utest.Assert;

class AutomatedTests
{
    var dc:DebugClient;
    public function new()
    {

    }

    @:keep public function setup() 
    {
       dc = new DebugClient('node', './out/node/nodeDebug.js', 'node');
	   return dc.start();
    }

    @:keep public function testFieldIsSome() 
    {
        Assert.isTrue(true,"testing works");
    }

    @:keep public function teardown() 
    {
       dc.stop();
    }
} 