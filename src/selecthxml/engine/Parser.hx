package selecthxml.engine;
import selecthxml.engine.Type;

class Parser {
	var lexer:SelectorLexer;
	var buffer:Array<Token>;

	public function new(lexer:SelectorLexer) {
		this.lexer = lexer;
		buffer = new Array<Token>();
	}
	
	public function parse():Selector {
		var parts = [];
		while (true) {
			skipWhitespace();
			var s = parseSimple();
			parts.push(s);
			skipWhitespace();		
			var t = readToken();			
			switch(t.def) {
				case TGt:    s.combinator = Child;
				case TPlus:  s.combinator = AdjacentSibling;
				case TTilde: s.combinator = GeneralSibling;					
				case TEof:
					break;
				default:
					pushToken(t);
					s.combinator = Descendant;
			}
		}
		return parts;
	}
	
	public function parseSimple():SelectorPart {
		var part = {
			universal: false,
			id: null,
			tag: null,
			classes: [],
			attrs: [],
			pseudos: [],
			combinator: null
		}
		var failed = true;
		while(true) {
			var t = readToken();
			switch(t.def) {
				case TAsterisk:
					if (part.universal)
						// TODO: Proper selector order
						throw EAlreadyUniversal(t);
					part.universal = true;
					failed = false;					
				// tag selector (div)
				case TAlpha(s):
					pushToken(t);
					part.tag = parseIdent();
					failed = false;				
				// id selector (#id)
				case THash:
					var name = parseNmChar();
					if (name.length == 0)
						unexpected(readToken());
					part.id = name;
					failed = false;
				// class selector (.class)
				case TDot:
					part.classes.push(parseIdent());
					failed = false;
				// pseudo selector (:psuedo)
				case TColon:
					t = readToken();
					switch(t.def) {
						// Support double colon ::
						case TColon:							
						default: pushToken(t);
					}					
					var ident = parseIdent();
					var ps = null;
					switch(ident) {
						case "root":            ps = PsRoot;
						case "nth-child", "nth-last-child", "nth-of-type", "nth-last-of-type": 
							expect(TParenOpen);
							var nth = parseNth();
							skipWhitespace();
							expect(TParenClose);
							switch(ident) {
								case "nth-child":        ps = PsNthChild(nth.a, nth.b);
								case "nth-last-child":   ps = PsNthLastChild(nth.a, nth.b);
								case "nth-of-type":      ps = PsNthOfType(nth.a, nth.b);
								case "nth-last-of-type": ps = PsNthLastOfType(nth.a, nth.b);
							}
						case "first-child":      ps = PsFirstChild;
						case "last-child":       ps = PsLastChild;
						case "first-of-type":    ps = PsFirstOfType;
						case "last-of-type":     ps = PsLastOfType;
						case "only-child":       ps = PsOnlyChild;
						case "only-of-type":     ps = PsOnlyOfType;
						case "empty":            ps = PsEmpty;
						case "link":             ps = PsLink;
						case "visited":          ps = PsVisited;
						case "active":           ps = PsActive;
						case "hover":            ps = PsHover;
						case "focus":            ps = PsFocus;
						case "target":           ps = PsTarget;
						case "lang(fr)":     
							expect(TParenOpen);
							skipWhitespace();
							ident = parseIdent();
							skipWhitespace();
							expect(TParenClose);
							ps = PsLang(ident);								
						case "enabled":          ps = PsEnabled;
						case "disabled":         ps = PsDisabled;
						case "checked":          ps = PsChecked;
						case "first-line":      ps = PsFirstLine;
						case "first-letter":    ps = PsFirstLetter;
						case "before":          ps = PsBefore;
						case "after":           ps = PsAfter;
						case "not":
							expect(TParenOpen);
							var simple = parseSimple();
							expect(TParenClose);
							ps = PsNot(simple);								
						default:
							var min = t.pos.min;
							throw EInvalidPseudo(ident, {min: min, max: min + ident.length});
					}
					part.pseudos.push(ps);
					failed = false;

				// Parse attr selector ([attr=value])
				case TSquareBrkOpen:
					skipWhitespace();
					// Read name
					var name = parseIdent();
					skipWhitespace();
					// Read operator (potentially)
					t = readToken();
					var op = null;
					switch(t.def) {
						case TTilde:    expect(TEquals); op = WhitespaceSeperated; // ~=
						case TPipe:     expect(TEquals); op = HyphenSeparated; // |=
						case TCaret:    expect(TEquals); op = BeginsWith; // ^=
						case TDollar:   expect(TEquals); op = EndsWith; // $=									
						case TAsterisk: expect(TEquals); op = Contains; // *=
						case TEquals:   op = Exactly; 
						case TSquareBrkClose:
							part.attrs.push( { name: name, value: null, operator: None } );
							failed = false;
							continue;
						default: unexpected(t);
					}
					skipWhitespace();
					// Read value
					t = readToken();
					var value = "";
					switch(t.def) {
						case TString(s): 
							value = s;
						default: 
							pushToken(t);
							value = parseIdent();
					}
					skipWhitespace();
					expect(TSquareBrkClose);
					part.attrs.push({ name: name, value: value, operator: op });
					failed = false;
				default: 
					pushToken(t);
					break;
			}
		}
		if (failed)
			throw EExpectedSelector(readToken());
		return part;
	}	
	
	function parseNth() {
		skipWhitespace();
		var t = readToken();
		switch(t.def) {
			case TAlpha(s):
				switch(s) {
					case "odd":  
						// :nth-child(odd)
						return { a: 2, b: 1 };
					case "even": 
						// :nth-child(even)
						return { a: 2, b: 0 };
					case "n": 
						pushToken(t);
						// :nth-child(n+2)
						return parseNthNext(1);
					default: 
						unexpected(t);
				}			
			case TPlus, TMinus:
				var sign = Type.enumEq(t.def, TPlus) ? 1 : -1;
				t = readToken();
				switch(t.def) {
					case TAlpha(s):
						if (s != "n")
							unexpected(t);
						pushToken(t);
						// :nth-child(-n)
						return parseNthNext(sign < 0 ? -1 : 0);
					case TInteger(v):
						// :nth-child(-2n)
						return parseNthNext(v * sign);
					default: 
						unexpected(t);
				}
			case TInteger(v):
				// :nth-child(2n)
				return parseNthNext(v);				
			default:
				unexpected(t);
		}
		return null;
	}
	
	function parseNthNext(a:Int) {
		skipWhitespace();
		var t = readToken();
		switch(t.def) {
			case TParenClose:
				pushToken(t);
				// :nth-child(-2)
				return { a:0, b: a };				
			case TAlpha(s):
				if (s != "n")
					unexpected(t);	
				skipWhitespace();
				t = readToken();
				switch(t.def) {
					case TMinus, TPlus:
						pushToken(t);
						// :nth-child(2n+2)
						return { a:a, b:parseInteger(true) };
					case TInteger(v):
						pushToken(t);
						// :nth-child(2n+2)
						return { a:a, b:parseInteger(true) };							
					case TParenClose:
						pushToken(t);
						// :nth-child(-2n)
						return { a:a, b:0 }					
					default: 
						unexpected(t);
				}		
			default: 
				unexpected(t);
		}
		return null;
	}
	
	function parseInteger(allowWhitespace:Bool):Null<Int> {
		var t = readToken();
		var sign = 1;
		switch(t.def) {
			case TMinus: 
				sign = -1; 
				if(allowWhitespace) skipWhitespace();
				t = readToken();				
			case TPlus: 
				sign = 1; 
				if(allowWhitespace) skipWhitespace();
				t = readToken();				
			default:
		}
		switch(t.def) {
			case TInteger(v): return v * sign;				
			default: unexpected(t);
		}
		return null;
	}
	
	function parseIdent():String {
		// (-?(?:[a-zA-Z]|_)(?:[a-zA-Z0-9]|-|_)*)
		var str = "";
		var t = readToken();
		switch(t.def) {
			case TMinus:      
				str += "-";
				t = readToken();
				switch (t.def) {
					case TAlpha(s):   str += s;
					case TUnderscore: str += "_";
					default: unexpected(t);
				}				
			case TAlpha(s):   str += s;
			case TUnderscore: str += "_";
			default: unexpected(t);				
		}
		str += parseNmChar();
		return str;
	}
	
	function parseNmChar():String {
		// [_a-z0-9-]|{nonascii}|{escape}
		var str = "";
		while (true) {
			var t = readToken();
			switch (t.def) {					
				case TAlpha(s):   str += s;
				case TInteger(v): str += v;
				case TMinus:      str += "-";
				case TUnderscore: str += "_";					
				default: 
					pushToken(t);
					break;
			}		
		}
		return str;
	}
	
	function skipWhitespace():Void {
		while (true) {
			var t = readToken();
			switch(t.def) {
				case TWhitespace:
				default:
					pushToken(t);
					return;				
			}
		}
	}
	
	function readToken():Token {
		if (buffer.length > 0)
			return buffer.shift();
		return lexer.readToken();
	}
	
	function pushToken(t:Token):Void {
		buffer.push(t);
	}
	
	function unexpected(t:Token):Void {
		throw EUnexpectedToken(t);
	}
	
	function expect(t:TokenDef):Void {
		var tk = readToken();
		if (!Type.enumEq(tk.def, t))
			throw EExpected(t, tk);
	}	
}