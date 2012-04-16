package selecthxml.engine;
import selecthxml.engine.Type;

class SelectEngine {
	static inline var ELEMENT_NODE = 1;
	
	public function new() {}
	
	public function query(selector:Selector, root:SelectableDom):Array<SelectableDom> {

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
							ctx = ctx.parentNode;
							if (ctx == null || ctx.nodeType != ELEMENT_NODE) {
								// Reached top of DOM tree
								failed = true;
								break;
							}
							if(matches(part, ctx))
								break;
						}
					case Child:
						ctx = ctx.parentNode;
						if (ctx == null || ctx.nodeType != ELEMENT_NODE || !matches(part, ctx))
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
	
	function getCandidates(selector:Selector, root:SelectableDom):Array<SelectableDom> {
		var p = selector[selector.length-1];
		var candidates = [];
		// Look for candidates using the most efficent methods available
		if (p.id != null) {
			var el = untyped root.getElementById(p.id);
			if (el != null && matches(p, el))
				candidates.push(el);
		}
		else if (p.classes.length > 0 && untyped root.getElementsByClassName != null) {
			var names = p.classes.join(" ");
			var list:Array<SelectableDom> = untyped root.getElementsByClassName(names);
			for (i in 0 ... list.length)
				if(matches(p, list[i]))
					candidates.push(list[i]);
		}
		else if (p.tag != null) {
			var list = root.getElementsByTagName(p.tag);
			for (i in 0 ... list.length)
				if(matches(p, list[i]))
					candidates.push(list[i]);
		}
		else {
			var list = root.getElementsByTagName("*");
			for (i in 0 ... list.length)
				if(matches(p, list[i]))
					candidates.push(list[i]);
		}
		return candidates;
	}

	function matches(part:SelectorPart, el:SelectableDom):Bool {
		if (part.id != null) {
			if (el.getAttribute("id") != part.id) 
				return false;
		}		
		if (part.tag != null) {
			if (el.nodeName.toLowerCase() != part.tag.toLowerCase())
				return false;
		}		
		if (part.classes.length > 0) {
			var c = el.className.split(" ");
			for(className in part.classes) 
				if(!Lambda.has(c, className))
					return false;
		}
		if (part.attrs.length > 0) {
			for (attr in part.attrs) {
				var value = el.getAttribute(attr.name);
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
						var n = el.previousSibling;
						while (n != null) {
							if (n.nodeType == ELEMENT_NODE)
								count++;
							n = n.previousSibling;
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthOfType(a, b):
						if (!hasParent(el))
							return false;
						var count = 1;
						var n = el.previousSibling;
						var tag = part.tag == null ? el.nodeName :  part.tag;
						while (n != null) {
							if (n.nodeType == ELEMENT_NODE && n.nodeName == tag.toUpperCase())
								count++;
							n = n.previousSibling;
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthLastChild(a, b):
						if (!hasParent(el))
							return false;
						var count = 1;
						var n = el.nextSibling;
						while (n != null) {
							if (n.nodeType == ELEMENT_NODE)
								count++;
							n = n.nextSibling;
						}
						if (!matchNth(count, a, b))
							return false;
							
					case PsNthLastOfType(a, b):
						var count = 1;
						var n = el.nextSibling;
						var tag = part.tag == null ? el.nodeName :  part.tag;
						while (n != null) {
							if (n.nodeType == ELEMENT_NODE && n.nodeName == tag.toUpperCase())
								count++;
							n = n.nextSibling;
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
						var tag = part.tag == null ? el.nodeName :  part.tag;
						if (!isFirst(el, tag)) 
							return false;
					case PsLastOfType:
						var tag = part.tag == null ? el.nodeName :  part.tag;
						if (!isLast(el, tag))
							return false;
					case PsOnlyOfType:
						var tag = part.tag == null ? el.nodeName :  part.tag;
						if (!isFirst(el, tag) || isLast(el, tag)) 
							return false;
					case PsEmpty:
						if (el.firstChild != null)
							return false;
					//case PsFocus:
						//if (el != untyped elem.ownerDocument.activeElement)
							//return false;						
					//case PsEnabled:
						//var input:js.Dom.FormElement = cast el;						
						// Isn't a match if disabled, a hidden form input, or not applicable
						//if (input.type == null || input.type == "hidden")
							//return false;
						//if (input.disabled == null || input.disabled == true)
							//return false;							
					//case PsDisabled:
						//var input:js.Dom.FormElement = cast el;
						// Isn't a match if enabled or not applicable
						//if (input.disabled == null || input.disabled == false)
							//return false;
					case PsChecked:
						if (untyped el.checked == null || untyped el.checked == false)
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
	
	function previousSiblingElement(e:SelectableDom):SelectableDom {
		while (true) {
			e = e.previousSibling;
			if (e == null || e.nodeType == ELEMENT_NODE)
				break;
		}
		return e;
	}
	
	inline function hasParent(el:SelectableDom):Bool {
		return el.parentNode != null;
	}
	
	function isFirst(el:SelectableDom, ?type:String):Bool {
		while (true) {
			el = el.previousSibling;
			if (el == null)
				break;
			if (el.nodeType == ELEMENT_NODE && (type == null || el.nodeName == type.toUpperCase()))
				return false;			
		}		
		return true;
	}
	
	function isLast(el:SelectableDom, ?type:String):Bool {
		while (true) {
			el = el.nextSibling;
			if (el == null)
				break;
			if (el.nodeType == ELEMENT_NODE && (type == null || el.nodeName == type.toUpperCase()))
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