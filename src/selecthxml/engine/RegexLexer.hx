package selecthxml.engine;
import selecthxml.engine.Type;

class RegexLexer {
	/*
	 * alpha      ([a-zA-Z]+)
	 * string1    "((?:[\t !#$%&(-~]|\\")*)"
	 * string2    '((?:[\t !#$%&(-~]|\\')*)'
	 * num        ([0-9]+)
	 * chars      ([.#:*[\]()>+-\\~^$|=_])
	 * whitespace (\s+)
	 * re ^(?:{alpha}|{num}|{string1}|{string2}|{chars}|{whitespace})
	 */
	static var re:EReg = ~/^(?:([a-zA-Z]+)|([0-9]+)|"((?:[\t !#$%&(-~]|\\")*)"|'((?:[\t !#$%&(-~]|\\')*)'|([.#:*[\]()>+-\\~^$|=_])|(\s+))/;

	var s:String;
	var lastMin:Int;
	var inputLength:Int;
	
	public function new(input:String) {
		s = input;
		lastMin = 0;
		inputLength = input.length;
	}
	
	public function readToken():Token {
		var token = readTokenDef();
		var min = lastMin;
		var max = inputLength - s.length;
		lastMin = max;		
		return { def: token, pos: {min: min, max: max} }
	}
	
	public function readTokenDef():TokenDef {
		if (!re.match(s)) {
			if (s.length == 0)
				return TEof;
			var startPos = inputLength - s.length;
			throw EInvalidCharacter(s.charAt(0), { min:startPos, max:startPos + 1 } );
		}		
		s = re.matchedRight();
		
		if (re.matched(1) != null)      return TAlpha(re.matched(1));
		else if (re.matched(2) != null) return TInteger(Std.parseInt(re.matched(2)));
		else if (re.matched(3) != null) return TString(re.matched(3));
		else if (re.matched(4) != null) return TString(re.matched(4));
		else if (re.matched(5) != null) {
			switch(re.matched(5)) {
				case ".":  return TDot;
				case "#":  return THash;
				case ":":  return TColon;
				case "*":  return TAsterisk;
				case "[":  return TSquareBrkOpen;
				case "]":  return TSquareBrkClose;
				case "(":  return TParenOpen;
				case ")":  return TParenClose;
				case ">":  return TGt;
				case "+":  return TPlus;
				case "-":  return TMinus;
				case "~":  return TTilde;
				case "^":  return TCaret;
				case "$":  return TDollar;
				case "|":  return TPipe;
				case "=":  return TEquals;
				case "_":  return TUnderscore;
			}
		}
		else if (re.matched(6) != null) return TWhitespace;
		return null;
	}	
}