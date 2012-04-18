package selecthxml;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;

import selecthxml.engine.Lexer;
import selecthxml.engine.TypeResolver;

import tink.core.types.Option;
using tink.macro.tools.MacroTools;

#end

import selecthxml.engine.Parser;

class SelectDom 
{	
	@:macro static public function select<T>(xml:ExprOf<TypedXml<T>>, selectionString:String)
	{
		if (selectionString == null || selectionString.length == 0)
			return Context.error("Selection string expected.", xml.pos);
		
		var lexer = new Lexer(new haxe.io.StringInput(selectionString));
		var parser = new Parser(lexer);
		var selector = parser.parse();
		
		var selectorExprs = [];
		for (s in selector)
			selectorExprs.push(s.toExpr());
			
		#if SELECTHXML_RUNTIME_PARSING
		var ret = ["selecthxml", "SelectDom", "runtimeSelect"].drill(xml.pos).call([xml, selectionString.toExpr()], xml.pos);
		#else
		var ret = ["selecthxml", "SelectDom", "applySelector"].drill(xml.pos).call([xml, selectorExprs.toArray()], xml.pos);
		#end
		
		if (isSingular(selector))
			ret = ret.field("shift").call();
			
		var ret = switch(TypeResolver.resolve(xml, selector))
		{
			case Option.None:
				ret;
			case Option.Some(f):
				if (isSingular(selector))
					EFunction(null, f.instantiate([ret]).func([], TPath(f))).at(xml.pos).call([]);
				else
				{
					var funcExpr = [
						"xmls".define(ret),
						"ret".define([].toExpr()),
						"xmls".resolve().iterate(
							"ret".resolve().field("push").call([f.instantiate(["xml".resolve()])])
						, "xml"),
						"ret".resolve()
					].toBlock();
					EFunction(null, funcExpr.func([], "Array".asComplexType([TPType(TPath(f))]))).at(xml.pos).call([]);
				}
		}
		return ret;
	}
		
	#if macro
	
	static inline function isSingular(s:selecthxml.engine.Type.Selector):Bool
		return s[s.length - 1].id != null
	
	#else

	@:allowConstraint static public inline function getXml<T:Xml>(result:TypedResult<T>):T
		return untyped result.__x_m_l__
	
	static public function runtimeSelect<T>(xml:TypedXml<T>, selectionString:String)
	{
		#if flash8
		var lexer = new selecthxml.engine.Lexer(new haxe.io.StringInput(selectionString));
		#else
		var lexer = new selecthxml.engine.RegexLexer(selectionString);
		#end
		var parser = new Parser(lexer);
		var selector = parser.parse();	
		return applySelector(xml, selector);
	}
	
	static public function applySelector(xml:Xml, selector:selecthxml.engine.Type.Selector)
	{
		var xmlDom = new selecthxml.engine.XmlDom(xml);
		if (isIdOnly(selector))
		{
			var dom = xmlDom.getElementById(selector[0].id);
			if (dom == null) return [];
			return [dom.xml];
		}

		var engine = new selecthxml.engine.SelectEngine();
		var result = engine.query(selector, xmlDom);
		var ret = [];
		for (r in result)
			ret.push(cast(r, selecthxml.engine.XmlDom).xml);
		return ret;
	}

	static inline function isIdOnly(s:selecthxml.engine.Type.Selector):Bool
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