package ;
import haxe.unit.TestRunner;

class TestMain 
{
	static public function main()
	{
		var runner = new TestRunner();
		runner.add(new TestBasic());
		runner.add(new TestTyped());
		runner.run();
	}
}