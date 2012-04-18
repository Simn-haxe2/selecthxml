package ;
import haxe.unit.TestRunner;
import tink.devtools.Benchmark;

class TestMain 
{
	static public function main()
	{
		#if !macro
		var runner = new TestRunner();
		runner.add(new TestBasic());
		runner.add(new TestTyped());
		Benchmark.measure("Running", runner.run());
		#end
	}
}