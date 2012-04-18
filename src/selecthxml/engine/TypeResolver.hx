package selecthxml.engine;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tink.core.types.Option;
import tink.core.types.Outcome;

import selecthxml.engine.Type;

using tink.core.types.Outcome;
using tink.macro.tools.MacroTools;

#if macro

class TypeResolver 
{
	static var typeCache:Hash<TypePath> = new Hash();
	
	static public function resolve<T>(xml:ExprOf<TypedXml<T>>, selector:Selector)
	{
		var docType = switch(getDocumentType(xml))
		{
			case Success(d): d;
			case Failure(_): return None;
		}
		
		var tPath = switch(matchFields(docType, selector))
		{
			case Success(f): f;
			case Failure(_): return None;
		}

		return Some(tPath);
	}
	
	static function getDocumentType(xml:Expr)
	{
		switch(xml.typeof())
		{
			case Success(t):
				switch(t)
				{
					case TType(t, p):
						if (t.toString() == "selecthxml.TypedXml" && p.length == 1)
							return Success(p[0]);
					default:
				}
			case Failure(_):
		}
		
		return Failure("No type found.");
	}
	
	static function matchFields(docType:Type, selector:Selector)
	{
		var docName = getName(docType);
		
		if (selector.length == 0)
			return Failure();
			
		var last = selector[selector.length - 1];
		if (last.tag == null)
			return Failure();
			
		var matchTag = last.tag.toLowerCase();
			
		var id = docName + "." +matchTag;
		
		if (typeCache.exists(id))
			return Success(typeCache.get(id));
			
		var fields = switch(docType.getFields())
		{
			case Success(f): f;
			case Failure(_): return Failure("Type has no fields.");
		}
		
		return switch(findField(fields, last))
		{
			case Failure(_):
				"No match".asFailure();
			case Success(field):
				var tPath = defineType(docType, field);
				typeCache.set(id, tPath);
				return tPath.asSuccess();			
		}
	}
	
	static function findField(fields:Iterable<ClassField>, selectorPart:SelectorPart)
	{
		var matchTag = selectorPart.tag.toLowerCase();
		
		var existencePseudoMatches = [];
		for (field in fields)
		{
			var pseudos = getPseudoMeta(field);
			for (pseudo in pseudos)
			{
				if (pseudo.elementName != matchTag)
					continue;
					
				for (attr in selectorPart.attrs)
				{
					if (attr.name.toLowerCase() != pseudo.attributeName)
						continue;
					if (pseudo.match == null)
					{
						existencePseudoMatches.push(field);
						continue;
					}
					switch(attr.operator)
					{
						case Exactly:
							if (attr.value.toLowerCase() == pseudo.match)
								return field.asSuccess();
						default:
					}
				}
			}
		
			var matchNames = getValueMeta(field);
			matchNames.push(field.name.toLowerCase());
			
			for (matchName in matchNames)
			{				
				if (matchName == matchTag)
					return field.asSuccess();
			}
		}
		
		if (existencePseudoMatches.length > 0)
			return existencePseudoMatches.pop().asSuccess();
		return Failure();
	}

	static function defineType(docType:Type, baseField:ClassField)
	{
		var fields = switch(baseField.type.getFields())
		{
			case Failure(f):
				Context.error("Field " +baseField.name + " has no fields.", baseField.pos);
			case Success(fields):
				fields;
		}
		
		var newFields = [];
		for (field in fields)
		{
			var fieldCType = switch(field.type.reduce())
			{
				case TFun(_): continue;
				default: field.type.reduce().toComplex();
			}
			var getter = makeGetter(field).func();
			var setter = makeSetter(field).func(["value".toArg(fieldCType)]);
			newFields.push(makeField("get_" +field.name , FFun(getter), field.pos, [APrivate]));
			newFields.push(makeField("set_" +field.name , FFun(setter), field.pos, [APrivate]));
			newFields.push(makeField(field.name, FProp("get_" +field.name, "set_" +field.name, fieldCType), field.pos));
		}
		
		var pack = ["selecthxml", "types", uncapitalize(getName(docType))];
		var name = capitalize(baseField.name);
		var tPath = {
			name: name,
			pack: pack,
			params: [],
			sub: null
		};

		Context.defineType( {
			pack: pack,
			name: name,
			pos: baseField.pos,
			params: [],
			meta: [],
			isExtern: false,
			kind: TDClass({name:"TypedResult", pack:["selecthxml"], params:[TPType("selecthxml.TypedXml".asComplexType([TPType(docType.toComplex())]))], sub:null}),
			fields: newFields
		});
	
		return tPath;
	}
	
	static function makeGetter(field:ClassField)
	{
		var matchNames = getValueMeta(field);
		var name = matchNames.length > 0 ? matchNames.pop() : field.name;
		var value = "__x_m_l__".resolve().field("get").call([name.toExpr()]);
				
		switch(field.type)
		{
			case TInst(t, p):
				switch(t.toString())
				{
					case "Int":
						value = ["Std", "parseInt"].drill().call([value]);
					case "Float":
						value = ["Std", "parseFloat"].drill().call([value]);
				}
			case TEnum(t, p):
				switch(t.toString())
				{
					case "Bool":
						value = value.binOp("true".toExpr(), OpEq, field.pos)
						.binOp(value.binOp("1".toExpr(), OpEq, field.pos), OpBoolOr, field.pos);
				}
			default:
		}

		return applyProcess(field, value, 0);
	}
	
	static function makeSetter(field:ClassField)
	{
		var value = applyProcess(field, "value".resolve(), 1);
		value = ["Std", "string"].drill().call([value]);
		return ["__x_m_l__".resolve().field("set").call([field.name.toExpr(), value]),
			field.name.resolve()].toBlock();
	}
	
	static function applyProcess(field:ClassField, value:Expr, procIndex:Int)
	{
		if (!field.meta.has("process")) return value;
		
		var by = { };
		Reflect.setField(by, "$value", value);
		
		var procMeta = field.meta.get().getValues("process");
		for (pm in procMeta)
		{
			if (pm.length <= procIndex) continue;
			value = pm[procIndex].substitute(by);
		}
		return value;
	}
	
	static function makeField(name:String, kind:FieldType, pos, ?access)
		return {
			name: name,
			pos: pos,
			doc: null,
			access: access == null ? [APublic] : access,
			meta: [],
			kind: kind
		}
	
	static function getName(t:Type)
	{
		switch(t)
		{
			case TType(t, _): return t.toString();
			default: return null;
		}
	}
	
	static function getValueMeta(field:ClassField)
	{
		if (!field.meta.has("value")) return [];
		
		var metas = [];
		for (v in field.meta.get().getValues("value"))
		{
			if (v.length != 1)
			{
				Context.warning("Invalid number of arguments to @value, expected String.", field.pos);
				continue;
			}
			switch(v[0].getName())
			{
				case Success(s):
					metas.push(s.toLowerCase());
				case Failure(_):
					Context.warning("Argument to @value must be String.", field.pos);
					continue;
			}
		}
		return metas;
	}
	
	static function getPseudoMeta(field:ClassField)
	{
		if (!field.meta.has("pseudo")) return [];
		
		var pseudos:Array<Pseudo> = [];
		for (v in field.meta.get().getValues("pseudo"))
		{
			if (v.length < 2 || v.length > 3)
			{
				Context.warning("Invalid number of arguments to @pseudo, expected (String, String, ?String)", field.pos);
				continue;
			}
			
			var pseudoData = Lambda.map(v, function(e)
				return switch(e.getName())
				{
					case Success(s): s.toLowerCase();
					case Failure(_):
						Context.warning("Arguments to @pseudo must be String.", field.pos);
						continue;
				});
				
			var pseudo = {
				elementName: pseudoData.pop(),
				attributeName: pseudoData.pop(),
				match: pseudoData.pop()
			};
			pseudos.push(pseudo);
		}
		return pseudos;
	}
	
	static function capitalize(s:String)
		return s.charAt(0).toUpperCase() + s.substr(1)
	static function uncapitalize(s:String)
		return s.charAt(0).toLowerCase() + s.substr(1)		
}

#end