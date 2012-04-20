package selecthxml.engine;

class XmlExtension 
{
	static public inline function getUpperCaseNodeName(xml:Xml)
		return xml.nodeName.toUpperCase()
	
	static public function getNextSibling(xml:Xml)
	{
		if (xml.parent == null) return null;
		var found = false;
		for (sibling in xml.parent.elements())
		{
			if (found) return sibling;
			#if flash
			if (untyped sibling._node == xml._node)
			#else
			if (sibling == xml)
			#end
				found = true;
		}
		return null;		
	}
	
	static public function getPreviousSibling(xml:Xml)
	{
		if (xml.parent == null) return null;
		var lastSibling = null;
		for (sibling in xml.parent.elements())
		{
			#if flash
			if (untyped sibling._node == xml._node)
			#else
			if (sibling == xml)
			#end
				return lastSibling;
			lastSibling = sibling;
		}
		return null;			
	}
	
	static public function getElementById(xml:Xml, id:String)
	{
		if (xml.nodeType == Xml.Element && xml.get("id") == id)
			return xml;

		for (child in xml.elements())
		{
			var elt = getElementById(child, id);
			if (elt != null)
				return elt;
		}
		
		return null;
	}

	static public function getElementsByTagName(xml:Xml, tagName:String):Iterable<Xml>
	{
		var accu = [];
		traverseGetElementsByTagName(xml.nodeType == Xml.Document ? xml.firstElement() : xml, tagName.toUpperCase(), accu);
		return accu;
	}
	
	static function traverseGetElementsByTagName(xml:Xml, tagName:String, accu:Array<Xml>)
	{
		if (tagName == "*" || xml.nodeName.toUpperCase() == tagName) accu.push(xml);
		for (child in xml.elements())
			traverseGetElementsByTagName(child, tagName, accu);
	}
	
	static public inline function getElementsByClassName(xml:Xml, className:String):Iterable<Xml>
	{
		var accu = [];
		traverseGetElementsByClassName(xml.nodeType == Xml.Document ? xml.firstElement() : xml, className, accu);
		return accu;
	}
	
	static function traverseGetElementsByClassName(xml:Xml, className:String, accu:Array<Xml>)
	{
		if (xml.get("class") == className) accu.push(xml);
		for (child in xml.elements())
			traverseGetElementsByClassName(child, className, accu);
	}
}