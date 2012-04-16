package selecthxml.engine;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

import selecthxml.engine.Type;
import selecthxml.TypedXml;

import tink.macro.tools.TypeTools;
import tink.macro.tools.ExprTools;
import tink.macro.tools.FunctionTools;
import tink.core.types.Outcome;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;
#end

/**
 * ...
 * @author Simon Krajewski
 */

class MacroHelper 
{
	#if macro
	
	static var extensionCache = new Hash<ComplexType>();
	
	static public function makeFunction(xml:Expr, selectionString:String)
	{
		var lexer = new Lexer(new haxe.io.StringInput(selectionString));
		var parser = new Parser(lexer);
		var selector = parser.parse();
		
		var ctype = TPath( { name: "Xml", pack: [], sub: null, params: [] } );
		
		var baseReturn = "selecthxml.SelectDom.runtimeSelect".resolve().call([xml, selectionString.toExpr()]);
		var funcExpr = switch(getXmlType(Context.typeof(xml), selector))
		{
			case Success(t):
				
				var fields = t.type.getFields().sure();
				if (fields.length > 0)
				{
					var fullName = (t.basePack.length > 0 ? t.basePack.join(".") + "." : "")
						+ t.baseName.charAt(0).toLowerCase() + t.baseName.substr(1)
						+ "." +t.name.charAt(0).toUpperCase() + t.name.substr(1);
					if (!extensionCache.exists(fullName))
						extensionCache.set(fullName, createExtension( { name: "TypedResult", pack:["selecthxml"], params:[], sub:null }, fields, t));
					ctype = extensionCache.get(fullName);
					if (haxe.macro.Context.defined('display'))
						EReturn("null".resolve()).at();
					else
						[
							"xmls".define(baseReturn),
							"ret".define([].toExpr()),
							"xmls".resolve().iterate(
								"ret".resolve().field("push").call([("selecthxml.types." +fullName).instantiate(["xml".resolve()])])
							, "xml"),
							EReturn(isSingular(selector) ? "ret".resolve().field("shift").call() : "ret".resolve()).at()
						].toBlock();
				}
			default:
				EReturn(isSingular(selector) ? baseReturn.field("shift").call() : baseReturn).at();
		}

		return EFunction(null, FunctionTools.func(funcExpr, [], isSingular(selector) ? ctype : "Array".asComplexType([TPType(ctype)]), null, false)).at().call([]);	
	}

	static inline function isSingular(s:Selector):Bool
	{
		return s[s.length - 1].id != null;
	}	
	
	static function getXmlType(t:haxe.macro.Type, s:Selector):Outcome<ExtensionType, Void>
	{
		var last = s[s.length - 1];
		if (last.tag == null)
			return Failure();

		var p = switch(t)
		{
			case TType(ty, p):
				if (ty.toString() != "selecthxml.TypedXml")
					return Failure();
				p[0];
			default:
				return Failure();
		}
		var pt = switch(p)
		{
			case TType(pt, _):
				pt.get();
			default:
				return Failure();
		}
		switch(pt.type)
		{
			case TAnonymous(ano):
				for (field in ano.get().fields)
				{
					var args = getMetaArgs(field.meta, 'pseudo');
					if (args.length >= 2 && last.tag.toLowerCase() == args[0].toLowerCase())
					{
						for (i in last.attrs)
						{
							if (i.name.toLowerCase() != args[1].toLowerCase())
								continue;
							if (args.length == 2)
								return Success(makeXmlTypeReturn(pt.pack, pt.name, field, p));
							switch(i.operator)
							{
								case Exactly:
									if (i.value.toLowerCase() == args[2].toLowerCase())
										return Success(makeXmlTypeReturn(pt.pack, pt.name, field, p));
								default:
							}
							
						}
					}
					var name = field.name;
					var args = getMetaArgs(field.meta, 'value');
					if (args.length > 0)
						name = args[0];
						
					if (name.toLowerCase() == last.tag.toLowerCase())
						return Success(makeXmlTypeReturn(pt.pack, pt.name, field, p));
				}
			default:
		}
		return Failure();
	}
	
	static inline function makeXmlTypeReturn(pack:Array<String>, baseName:String, field:ClassField, baseType:Type)
	{
		return {
			type: Context.follow(field.type),
			basePack: pack,
			baseName: baseName,
			name: field.name.charAt(0).toUpperCase() + field.name.substr(1),
			baseType: baseType
		};
	}

	static function createExtension(base:TypePath, fields:Array<ClassField>, t:ExtensionType)
	{
		var tdFields = [];

		for (field in fields)
		{
			tdFields.push(makeField(field.name, FProp("get_" +field.name, "set_" +field.name, TypeTools.toComplex(field.type))));
			tdFields.push(makeField("get_" +field.name,
				FFun(FunctionTools.func(Context.parse("return " +getValueString(field), Context.currentPos()), null, null, null, false)),
				true));
			tdFields.push(makeField("set_" +field.name,
				FFun(FunctionTools.func(Context.parse("{__x_m_l__.set('" +field.name + "', Std.string(v)); return " +field.name+ ";}", Context.currentPos()), [FunctionTools.toArg("v", field.type.toComplex())], field.type.toComplex(), null, false)),
				true));
		}

		var pack = t.basePack.copy();
		pack.push(t.baseName.charAt(0).toLowerCase() + t.baseName.substr(1));
		pack.unshift("types");
		pack.unshift("selecthxml");		
		
		base.params = [TPType(TPath( {
			pack: ["selecthxml"],
			name: "TypedXml",
			sub: null,
			params: [TPType(t.baseType.toComplex())]
		}))];

		var td = {
			name: t.name,
			pack: pack,
			pos: Context.currentPos(),
			meta: [],
			params: [],
			isExtern: false,
			kind: TDClass(base),
			fields: tdFields
		};

		Context.defineType(td);

		return TPath( {
			name: t.name,
			pack: pack,
			params: [],
			sub: null
		});		
	}
	
	static function makeField(name, kind, priv = false)
	{
		return {
			name:name,
			kind:kind,
			pos:Context.currentPos(),
			access:[priv ? APrivate : APublic],
			meta:[],
			doc:null
		};
	}
	
	static function getValueString(n:ClassField)
	{
		var name = n.name;
		var args = getMetaArgs(n.meta, 'value');
		if (args.length > 0)
			name = args[0];
			
		var ret = "__x_m_l__.get('" +name + "')";
		
		switch(n.type)
		{
			case TInst(t, p):
				switch(t.toString())
				{
					case "Int":
						return "Std.parseInt(" + ret + ")";
					case "Float":
						return "Std.parseFloat(" + ret + ")";
				}
			case TEnum(t, p):
				switch(t.toString())
				{
					case "Bool":
						return ret + "== 'true' || " +ret+ " == '1'";
				}
			default:
		}
		return ret;
	}
	
	static function getMetaArgs(metadata:MetaAccess, name:String)
	{
		if (!metadata.has(name)) return [];
		
		var ret = [];
		for (meta in metadata.get())
		{
			if (meta.name == name)
			{
				for (param in meta.params)
				{
					switch(param.getName())
					{
						case Success(s):
							ret.push(s);
						default:
					}
				}
			}
		}
		return ret;
	}
	
	#end
}

typedef ExtensionType = { type:Type, basePack:Array<String>, baseName:String, name:String, baseType:Type };