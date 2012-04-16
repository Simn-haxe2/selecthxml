package selecthxml.engine;

import selecthxml.engine.Type;

class XmlDom
{
	public var xml(default, null):Xml;
	
	public var className:String;
	public var nodeName:String;
	public var nodeType:Int;
	
	public var childNodes:Array<SelectableDom>;
	public var parentNode:SelectableDom;
	public var firstChild:SelectableDom;
	public var nextSibling:SelectableDom;
	public var previousSibling:SelectableDom;

	var index:Int;
	
	var attrCache:Hash<Hash<Array<XmlDom>>>;
	var tagCache:Hash<Array<XmlDom>>;
	
	public function new(xml:Xml, ?parent:XmlDom, ?index:Null<Int>) 
	{
		this.index = index;
		if (xml.nodeType == Xml.Element)
		{
			parentNode = parent;
			nodeName = xml.nodeName.toUpperCase();
			className = xml.exists("class") ? xml.get("class") : "";			
			nodeType = 1;
		}
		else
			nodeType = 0;
			
		this.xml = xml;
		resetCache();
		
		getChildNodes();
		firstChild = childNodes[0];
	}
	
	public function resetCache()
	{
		attrCache = new Hash();
		attrCache.set("id", new Hash());
		attrCache.set("class", new Hash());
		tagCache = new Hash();
		childNodes = null;
	}
	
	// Dom interface
	
	inline public function getAttribute( attr : String )
	{
		return xml.get(attr);
	}
	
	inline public function getElementById(id:String):XmlDom
	{
		return findElementsByAttribute("id", id).shift();
	}
	
	inline public function getElementsByClassName(className:String) : Array<XmlDom>
	{
		return findElementsByAttribute("class", className);
	}
	
	public function getElementsByTagName(tag:String):Array<XmlDom>
	{
		tag = tag.toUpperCase();
		if (!tagCache.exists(tag))
		{
			var accu = [];
			findElements(function(xmlDom) return tag == "*" || xmlDom.nodeName == tag, accu);
			tagCache.set(tag, accu);
		}
		return tagCache.get(tag);
	}
	
	// Convenience
	
	public function findElements(cb:XmlDom -> Bool, accu:Array<XmlDom>)
	{
		if (xml.nodeType == Xml.Element && cb(this)) accu.push(this);
		for (child in childNodes)
			cast(child, XmlDom).findElements(cb, accu);
	}
	
	public function findElementsByAttribute(attr:String, attrValue:String)
	{
		if (!attrCache.exists(attr))
			attrCache.set(attr, new Hash());
		if (attrCache.get(attr).exists(attrValue)) return attrCache.get(attr).get(attrValue);
		
		var accu:Array<XmlDom> = [];
		findElements(function(XmlDom) return XmlDom.getAttribute(attr) == attrValue, accu);
		attrCache.get(attr).set(attrValue, accu);
		return accu;
	}
	
	function determineSiblings()
	{
		nextSibling = getNextSibling();
		previousSibling = getPreviousSibling();
	}
	
	// Getter
	
	function getChildNodes()
	{
		if (childNodes != null) return;
		else
		{
			var childNodes:Array<SelectableDom> = [];
			var i = 0;
			for (child in xml.elements())
				childNodes.push(new XmlDom(child, this, i++));
			this.childNodes = childNodes;
			for (child in childNodes)
				cast(child, XmlDom).determineSiblings();
		}
	}
	
	function getNextSibling()
	{
		if (parentNode == null) return null;
		var found = false;
		for (sibling in cast(parentNode, XmlDom).childNodes)
		{
			if (found) return sibling;
			if (cast(sibling, XmlDom).index == this.index)
				found = true;
		}
		return null;
	}
	
	function getPreviousSibling()
	{
		if (parentNode == null) return null;
		var lastSibling = null;
		for (sibling in cast(parentNode, XmlDom).childNodes)
		{
			if (cast(sibling, XmlDom).index == this.index) return lastSibling;
			lastSibling = sibling;
		}
		return null;		
	}
	
	public function toString()
	{
		return "XmlDom(" +nodeName+ ")";
	}
}