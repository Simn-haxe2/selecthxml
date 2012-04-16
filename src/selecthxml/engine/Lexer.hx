package selecthxml.engine;
import selecthxml.engine.Type;
import haxe.io.Input;

class Lexer {
	var input:Input;
	var currentPos:Int;
	var buffer:Array<Int>;

	public function new(input:Input) {
		this.input = input;
		buffer = [];
		currentPos = 1;
	}
	
	public function readToken():Token {		
		var min = currentPos;
		var token = readTokenDef();
		var max = currentPos;
		return { def: token, pos: {min: min, max: max} }
	}
	
	public function readTokenDef():TokenDef {
		var c = readChar();
		switch(c) {
			case 0: return TEof;
			case ".".code:  return TDot;
			case "#".code:  return THash;
			case ":".code:  return TColon;
			case "*".code:  return TAsterisk;
			case "[".code:  return TSquareBrkOpen;
			case "]".code:  return TSquareBrkClose;
			case "(".code:  return TParenOpen;
			case ")".code:  return TParenClose;
			case "\"".code: return readString("\"".code);
			case "'".code:  return readString("'".code);
			case ">".code: return TGt;
			case "+".code: return TPlus;
			case "-".code: return TMinus;
			case "~".code: return TTilde;
			case "^".code: return TCaret;
			case "$".code: return TDollar;
			case "|".code: return TPipe;
			case "=".code: return TEquals;
			case "_".code: return TUnderscore;
			default:
				// Alpha a-zA-Z
				if (isAlpha(c)) {
					var str = "";
					while (true) {
						str += String.fromCharCode(c);
						c = readChar();
						if (!isAlpha(c)) {
							pushChar(c);
							break;
						}						
					}
					return TAlpha(str);
				}
				// Number 0-9
				else if (isNumber(c)) {
					var str = "";
					while (true) {
						str += String.fromCharCode(c);
						c = readChar();
						if (!isNumber(c)) {
							pushChar(c);
							break;
						}		
					}
					return TInteger(Std.parseInt(str));
				}
				else if (isWhitespace(c)) {
					while (true) {
						c = readChar();
						if (!isWhitespace(c)) {
							pushChar(c);
							break;					
						}
					}
					return TWhitespace;
				}
				throw EInvalidCharacter(String.fromCharCode(c), { min: currentPos - 1, max: currentPos });
				return null;
		}
	}	
	
	function readString(quoteType:Int) {
		var str = "";
		var esc = false;
		var startPos = currentPos;
		while (true) {
			var c = readChar();
			if (esc == true) {
				esc = false;
				if (c == quoteType) {
					str += String.fromCharCode(c);
				}						
			}					
			else if (c == "\\".code) esc = true;
			else if (c == quoteType) break;
			else if (c == 0) throw EUnterminatedString({ min:startPos - 1, max:startPos });
			else str += String.fromCharCode(c);
		}
		return TString(str);
	}
	
	inline function isAlpha(c:Int) { 
		return (c >= "A".code && c <= "Z".code) || (c >= "a".code && c <= "z".code); 
	}
	
	inline function isNumber(c:Int) {
		return c >= "0".code && c <= "9".code;
	}
	
	inline function isWhitespace(c:Int) {
		return c == 32 || c == 9 || c == 13;
	}
	
	function readChar():Int {
		currentPos++;
		if (buffer.length > 0)
			return buffer.shift();		
		try { return input.readByte(); } catch (ex:Dynamic) { return 0; }
	}
	
	function pushChar(char:Int):Void {
		currentPos--;
		buffer.push(char);
	}
}