package selecthxml.engine;

enum TokenDef {
	TEof;
	TWhitespace;
	TAlpha(s:String); // A-Z
	TString(s:String);
	TInteger(v:Int);
	TAsterisk;
	TDot;
	THash;
	TColon;
	TSquareBrkOpen;
	TSquareBrkClose;
	TParenOpen;
	TParenClose;
	TGt;
	TPlus;
	TMinus;	
	TTilde;  // ~
	TCaret;  // ^
	TDollar; // $
	TPipe;   // |
	TEquals; // =
	TUnderscore;
}

typedef Token = {
	var def:TokenDef;
	var pos:{ min:Int, max:Int };
}

typedef SelectorLexer = {
	function readToken():Token;
}

enum Combinator {
    Descendant;
	Child; // >
	AdjacentSibling; // +
	GeneralSibling; // ~
}

enum AttrOperator {
	None;
	Exactly; // =
	WhitespaceSeperated; // ~=
	HyphenSeparated; // |=
	BeginsWith; // ^=
	EndsWith; // $=
	Contains; // *=
}

typedef AttrFilter = {	
	var name:String;
	var value:String;
	var operator:AttrOperator;
}

typedef NthValue = {
	var a:Int;
	var b:Int;
}

enum PseudoClass {
	PsRoot;
	PsNthChild(a:Int, b:Int);
	PsNthLastChild(a:Int, b:Int);
	PsNthOfType(a:Int, b:Int);
	PsNthLastOfType(a:Int, b:Int);
	PsFirstChild;
	PsLastChild;
	PsFirstOfType;
	PsLastOfType;
	PsOnlyChild;
	PsOnlyOfType;
	PsEmpty;
	PsLink;
	PsVisited;
	PsActive;
	PsHover;
	PsFocus;
	PsTarget;
	PsLang(cn:String);
	PsEnabled;
	PsDisabled;
	PsChecked;
	PsFirstLine;
	PsFirstLetter;
	PsBefore;
	PsAfter; 
	PsNot(s:SelectorPart);
}

typedef SelectorPart = {
	var universal:Bool;
	var id:Null<String>;
	var tag:Null<String>;
	var classes:Array<String>;
	var attrs:Array<AttrFilter>;
	var pseudos:Array<PseudoClass>;
	var combinator:Null<Combinator>;
}

typedef Selector = Array<SelectorPart>;

typedef ErrorPos = {
	var min:Int;
	var max:Int;	
}

enum ParseError {
	EExpected(expected:TokenDef, got:Token);
	EInvalidPseudo(p:String, pos:ErrorPos);
	EExpectedInteger(pos:ErrorPos);	
	EUnexpectedToken(t:Token);
	EInvalidCharacter(c:String, pos:ErrorPos);
	EUnterminatedString(pos:ErrorPos);
	EExpectedSelector(t:Token);
	EAlreadyUniversal(t:Token);
}

typedef Pseudo = {
	var elementName:String;
	var attributeName:String;
	@optional var match:String; 
}