package selecthxml.engine;
import selecthxml.engine.Type;
using selecthxml.engine.XmlExtension;

class SelectEngine {
	static inline var ELEMENT_NODE = 1;
	
	public function new() {}
	
	public function query(selector:Selector, root:Xml):Array<Xml> {

		var candidates = getCandidates(selector, root);		
		// TODO: Make this readable
		var results = [];		
		for (i in candidates) {			
			var ctx = i;
			var failed = false;
			for(j in 1 ... selector.length) {
				var part = selector[selector.length - j - 1];
				// Handle combinators
				switch(part.combinator) {
					case Descendant: 
						var found = false;
						while (true) {
							ctx = ctx.parent;
							if (ctx == null || ctx.nodeType != Xml.Element) {
								// Reached top of DOM tree
								failed = true;
								break;
							}
							if(matches(part, ctx))
								break;
						}
					case Child:
						ctx = ctx.parent;
						if (ctx == null || ctx.nodeType != Xml.Element || !matches(part, ctx))
							failed = true;
					case AdjacentSibling:						
						ctx = previousSiblingElement(ctx);
						if (ctx == null || !matches(part, ctx))  {
							failed = true;
							break;
						}
					case GeneralSibling:
						while (true) {							
							ctx = previousSiblingElement(ctx);
							if (ctx == null) {
								failed = true;
								break;
							}
							if (matches(part, ctx))
								break;
						}
				}
				if (failed) 
					break;
			}
			if (!failed)
				results.push(i);
		}		
		return results;
	}
	
	function getCandidates(selector:Selector, root:Xml):Array<Xml> {
		var p = selector[selector.length-1];
		var candidates = [];
		// Look for candidates using the most efficent methods available
		if (p.id != null) {
			var el = root.getElementById(p.id);
			if (el != null && matches(p, el))
				candidates.push(el);
		}
		else if (p.classes.length > 0) {
			var names = p.classes.join(" ");
			var list = root.getElementsByClassName(names);
			for (i in list)
				if (matches(p, i))
					candidates.push(i);
		}
		else if (p.tag != null) {
			var list = root.getElementsByTagName(p.tag);
			for (i in list)
				if (matches(p, i))
					candidates.push(i);
		}
		else {
			var list = root.getElementsByTagName("*");
			for (i in list)
				if (matches(p, i))
					candidates.push(i);
		}
		return candidates;
	}

	function matches(part:SelectorPart, el:Xml):Bool {
		if (part.id != null) {
			if (el.get("id") != part.id) 
				return false;
		}		
		if (part.tag != null) {
			if (el.getUpperCaseNodeName().toLowerCase() != part.tag.toLowerCase())
				return false;
		}		
		if (part.classes.length > 0) {
			var c = el.get("class");
			if (c == null) return false;
			var c = c.split(" ");
			for(className in part.classes) 
				if(!Lambda.has(c, className))
					return false;
		}
		if (part.attrs.length > 0) {
			for (attr in part.attrs) {
				var value = el.get(attr.name);
				if (value == null)
					return false;
				switch(attr.operator) {
					case None:
					case Exactly: 
						if (value != attr.value)
							return false;
					case WhitespaceSeperated:
						var c = value.split(" ");
						if(!Lambda.has(c, attr.value))
							return false;
					case HyphenSeparated:
						var c = value.split("-");
						if(!Lambda.has(c, attr.value))
							return false;
					case BeginsWith:
						if (!StringTools.startsWith(value, attr.value))
							return false;						
					case EndsWith:
						if (!StringTools.endsWith(value, attr.value))
							return false;
					case Contains:
						if (value.indexOf(attr.value) < 0)
							return false;
				}
			}
		}
		if (part.pseudos.length > 0) {
			for (i in part.pseudos) {
				switch(i) {
					case PsNthChild(a, b):
						if (!hasParent(el))
							return false;
						var count = 1;
						var n = el.getPreviousSibling();
						while (n != null) {
							if (n.nodeType == Xml.Element)
								count++;
							n = n.getPreviousSibling();
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthOfType(a, b):
						if (!hasParent(el))
							return false;
						var count = 1;
						var n = el.getPreviousSibling();
						var tag = part.tag == null ? el.getUpperCaseNodeName() :  part.tag;
						while (n != null) {
							if (n.nodeType == Xml.Element && n.getUpperCaseNodeName() == tag.toUpperCase())
								count++;
							n = n.getPreviousSibling();
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthLastChild(a, b):
						if (!hasParent(el))
							return false;
						var count = 1;
						var n = el.getNextSibling();
						while (n != null) {
							if (n.nodeType == Xml.Element)
								count++;
							n = n.getNextSibling();
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthLastOfType(a, b):
						var count = 1;
						var n = el.getNextSibling();
						var tag = part.tag == null ? el.getUpperCaseNodeName() :  part.tag;
						while (n != null) {
							if (n.nodeType == Xml.Element && n.getUpperCaseNodeName() == tag.toUpperCase())
								count++;
							n = n.getNextSibling();
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsFirstChild: 
						if (!hasParent(el) || !isFirst(el)) 
							return false;	
					case PsLastChild:
						if (!hasParent(el) || !isLast(el)) 
							return false;	
					case PsOnlyChild:
						if (!hasParent(el) || !isFirst(el) || !isLast(el)) 
							return false;
					case PsFirstOfType:
						var tag = part.tag == null ? el.getUpperCaseNodeName() :  part.tag;
						if (!isFirst(el, tag)) 
							return false;
					case PsLastOfType:
						var tag = part.tag == null ? el.getUpperCaseNodeName() :  part.tag;
						if (!isLast(el, tag))
							return false;
					case PsOnlyOfType:
						var tag = part.tag == null ? el.getUpperCaseNodeName() :  part.tag;
						if (!isFirst(el, tag) || isLast(el, tag)) 
							return false;
					case PsEmpty:
						if (el.firstChild != null)
							return false;
					case PsNot(s):
						if (matches(s, el))
							return false;
					default: 
						return false;
				}
			}
		}
		return true;
	}
	
	function previousSiblingElement(e:Xml):Xml {
		while (true) {
			e = e.getPreviousSibling();
			if (e == null || e.nodeType == Xml.Element)
				break;
		}
		return e;
	}
	
	inline function hasParent(el:Xml):Bool {
		return el.parent != null;
	}
	
	function isFirst(el:Xml, ?type:String):Bool {
		while (true) {
			el = el.getPreviousSibling();
			if (el == null)
				break;
			if (el.nodeType == Xml.Element && (type == null || el.getUpperCaseNodeName() == type.toUpperCase()))
				return false;			
		}		
		return true;
	}
	
	function isLast(el:Xml, ?type:String):Bool {
		while (true) {
			el = el.getNextSibling();
			if (el == null)
				break;
			if (el.nodeType == Xml.Element && (type == null || el.getUpperCaseNodeName() == type.toUpperCase()))
				return false;
		}		
		return true;
	}
	
	function matchNth(count:Int, a:Int, b:Int):Bool {
	    if (a == 0)
	        return count == b;
	    else if (a > 0) {
	        if (count < b)
	            return false;
	        return (count - b) % a == 0;
	    } else {
	        if (count > b)
	            return false;
	        return (b - count) % ( -a) == 0;
	    }
	}
}