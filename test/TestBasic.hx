package ;
import haxe.unit.TestCase;
import selecthxml.SelectDom;
import selecthxml.TypedXml;

using selecthxml.SelectDom;

class TestBasic extends TestCase
{
	var xml:Xml;
	
	override public function setup()
	{
		xml = XmlTest.getXml();
	}
	
	public function testId()
	{
		var s = xml.select("#login");
		assertEquals("POST", s.get("method"));
	}
	
	public function testClass()
	{
		var s = selecthxml.SelectDom.select(xml, ".group");
		assertEquals(2, s.length);
		assertEquals("span", s[0].nodeName);
		assertEquals("span", s[1].nodeName);
	}
	
	public function testTag()
	{
		var s = xml.select("form");
		assertEquals(2, s.length);
		assertEquals("/wiki/login", s[0].get("action"));
		assertEquals("/wiki/search", s[1].get("action"));
	}
	
	public function testAttr()
	{
		var s = xml.select("input[value]");
		assertEquals(3, s.length);
		assertEquals('hidden', s[0].get("type"));
		assertEquals('OK', s[1].get("value"));
		assertEquals('submit', s[2].get("type"));
	}
	
	public function testAttrEq()
	{
		var s = xml.select("input[name=url]");
		assertEquals(1, s.length);
		assertEquals('url', s[0].get("name"));
	}
	
	public function testComplex1()
	{
		var s = xml.select(".search *[value=OK]");
		assertEquals(1, s.length);
		assertEquals('submit', s[0].get("type"));
	}
	
	public function testComplex2()
	{
		var s = xml.select("body .all li *[alt=de] + span");
		assertEquals(1, s.length);
		assertEquals("Deutsch", s[0].firstChild().toString());
	}
	
	public function testNthChild()
	{
		var s = xml.select(".box_intro:nth-child(3) > span");
		assertEquals(3, s.length);
		assertEquals("img3", s[0].get("class"));
		assertEquals("title", s[1].get("class"));
		assertEquals("desc", s[2].get("class"));
	}
	
	public function testNthChildEvenOdd()
	{
		var s = xml.select(".box_intro:nth-child(odd) > span");
		assertEquals(6, s.length);
		assertEquals("img1", s[0].get("class"));
		assertEquals("title", s[1].get("class"));
		assertEquals("desc", s[2].get("class"));
		assertEquals("img3", s[3].get("class"));
		assertEquals("title", s[4].get("class"));
		assertEquals("desc", s[5].get("class"));
		
		var s = xml.select(".box_intro:nth-child(even) > span");
		assertEquals(6, s.length);
		assertEquals("img2", s[0].get("class"));
		assertEquals("title", s[1].get("class"));
		assertEquals("desc", s[2].get("class"));
		assertEquals("img4", s[3].get("class"));
		assertEquals("title", s[4].get("class"));
		assertEquals("desc", s[5].get("class"));
	}
	
	public function testNthOfType()
	{
		var s = xml.select("#login input:nth-of-type(2)");
		assertEquals(1, s.length);
		assertEquals('button', s[0].get("class"));
		
		s = xml.select(".langs ul li:nth-of-type(5n-4) img");
		assertEquals(3, s.length);
		assertEquals("en", s[0].get("alt"));
		assertEquals("de", s[1].get("alt"));
		assertEquals("cn", s[2].get("alt"));
	}
}