package test;
import utest.Assert;

class AutomatedTests
{
    public function new()
    {

    }

    @:keep public function setup() 
    {
       
    }

    @:keep public function testFieldIsSome() 
    {
        Assert.isTrue(true,"testing works");
    }

    @:keep public function teardown() 
    {
       
    }
}