package selecthxml;

import selecthxml.engine.Parser;
import selecthxml.engine.Type;
import selecthxml.engine.XmlDom;
import selecthxml.TypedXml;

#if macro

import selecthxml.engine.MacroHelper;
import haxe.macro.Context;
import haxe.macro.Expr;

#else

import selecthxml.engine.RegexLexer;
import selecthxml.engine.SelectEngine;

#end

class SelectDom
{
	#if !macro @:macro #end
	static public function select<T>(xml:ExprRequire<TypedXml<T>>, selectionString:String)
	{		
		if (selectionString == null || selectionString.length == 0)
			return Context.error("Selection string expected.", xml.pos);
						
		return MacroHelper.makeFunction(xml, selectionString);
	}
	
	@:allowConstraint static public inline function getXml<T:Xml>(result:TypedResult<T>):T
		return untyped result.__x_m_l__
		
	#if !macro
	
	static var lastXmlDom:XmlDom;
	static var selectorCache = new Hash<Selector>();
	
	static public function runtimeSelect(xml:Xml, selector:String)
	{
		if (lastXmlDom == null || lastXmlDom.xml != xml)
			lastXmlDom = new XmlDom(xml);

		var xmlDom = lastXmlDom;
		
		if (!selectorCache.exists(selector))
		{
			var lexer = new RegexLexer(selector);
			var parser = new Parser(lexer);
			selectorCache.set(selector, parser.parse());
		}
		
		var s = selectorCache.get(selector);

		if (isIdOnly(s))
		{
			var dom = xmlDom.getElementById(s[0].id);
			if (dom == null) return [];
			return [dom.xml];
		}
		
		var engine = new SelectEngine();
		var result = engine.query(s, xmlDom);
		var ret = [];
		for (r in result)
			ret.push(cast(r, XmlDom).xml);
		return ret;
	}

	static inline function isIdOnly(s:Selector):Bool
	{
		var p = s[0];		
		return s.length == 1 
			&& p.id != null 
			&& p.tag == null 
			&& p.classes.length == 0
			&& p.attrs.length == 0
			&& p.pseudos.length == 0
			&& p.combinator == null;
	}
	
	#end
}