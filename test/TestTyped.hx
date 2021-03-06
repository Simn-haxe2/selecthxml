package ;
import haxe.unit.TestCase;
import selecthxml.TypedXml;

using selecthxml.SelectDom;

typedef CustomHtml =
{
	var div: { 
		@value('class') var cl:String;
	};
	var a: { href: String };
	var form: { action:String, method: String };
	var body: { version: Int };
	var head: { offset: Float };
	@pseudo('input', 'type') var inputGeneral: { value: String };
	@pseudo('input', 'type', 'submit') var inputSubmit: { value: String };
	@pseudo('input', 'type', 'hidden') var inputHidden: { name:String, value: String };
	@value('class') var cl: { id: String };
	var el: {
		@process($value.split(":"), $value.join(":")) var list:Array<String>;
		@process(Lambda.array(Lambda.map($value.split(","), function(s) return Std.parseInt(s))), $value.join(",")) var intList:Array<Int>;
	};
}

class TestTyped extends TestCase
{
	var xml:TypedXml<CustomHtml>;
	
	override public function setup()
	{
		xml = XmlTest.getXml();
	}
	
	public function testAccess()
	{
		var s = xml.select("a");
		assertTrue(Std.is(s[0].href, String));
		assertTrue(Std.is(s[0].getXml(), Xml));
	}
	
	public function testStringValue()
	{
		var s = xml.select("form#login");
		assertEquals("/wiki/login", s.action);
		assertEquals("POST", s.method);
		assertTrue(Std.is(s.getXml(), Xml));
	}

	public function testIntValue()
	{
		var s = xml.select("body");
		assertTrue(Std.is(s[0].version, Int));
		assertEquals(5, s[0].version);
	}

	public function testFloatValue()
	{
		var s = xml.select("head");
		assertTrue(Std.is(s[0].offset, Float));
		assertEquals(9.2, s[0].offset);
	}
	
	public function testValueMeta()
	{
		var s = xml.select("div");
		assertEquals("all", s[0].cl);
		
		var s2 = xml.select("class#class1");
		assertEquals("class1", s2.id);
	}
	
	public function testPseudoMeta()
	{
		var s = xml.select("input[type=submit]");
		assertEquals("OK", s[0].value);
		assertEquals("button", s[0].getXml().get('class'));
	}

	public function testModify()
	{
		var s = xml.select("body");
		assertEquals(5, s[0].version);
		s[0].version = 20;
		assertEquals(20, s[0].version);
		assertEquals("20", s[0].getXml().get('version'));
		
		s = xml.select("body");
		assertTrue(Std.is(s[0].version, Int));
		assertEquals(20, s[0].version);
		assertEquals("20", s[0].getXml().get('version'));		
	}

	public function testXmlFallback()
	{
		var s = xml.select("span");
		assertTrue(Std.is(s[0], Xml));
	}

	public function testRetainTypedXml()
	{
		var s = xml.select("body")[0];
		assertTrue(Std.is(s, selecthxml.types.customHtml.Body));
		var s = s.getXml().select("form#login");
		assertEquals("/wiki/login", s.action);
		assertEquals("POST", s.method);
		assertTrue(Std.is(s.getXml(), Xml));
		assertTrue(Std.is(s, selecthxml.types.customHtml.Form));
	}
	
	public function testTypeExistence()
	{
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.Div") != null);
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.A") != null);
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.Form") != null);
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.Head") != null);
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.InputSubmit") != null);
		assertTrue(Type.resolveClass("selecthxml.types.customHtml.InputHidden") == null); // this was never created
	}

	public function testTypeCreation()
	{
		var t = new selecthxml.types.customHtml.A(Xml.parse("<a href='here' />").firstElement());
		assertEquals('here', t.href);
	}
	
	public function testProcessMeta()
	{
		var xml:TypedXml<CustomHtml> = Xml.parse("<el list='item1:item2:item3'></el>").firstChild();
		var el = xml.select("el")[0];
		assertEquals(3, el.list.length);
		assertEquals("item1", el.list[0]);
		assertEquals("item2", el.list[1]);
		assertEquals("item3", el.list[2]);
		el.list = ["newitem1", "newitem2"];
		assertEquals(2, el.list.length);
		assertEquals("newitem1", el.list[0]);
		assertEquals("newitem2", el.list[1]);
		
		var xml:TypedXml<CustomHtml> = Xml.parse("<el intList='9, 5, 1'></el>").firstChild();
		var el = xml.select("el")[0];
		assertEquals(3, el.intList.length);
		assertEquals(9, el.intList[0]);
		assertEquals(5, el.intList[1]);
		assertEquals(1, el.intList[2]);
		el.intList = [99, 98];
		assertEquals(2, el.intList.length);
		assertEquals(99, el.intList[0]);
		assertEquals(98, el.intList[1]);		
	}
}