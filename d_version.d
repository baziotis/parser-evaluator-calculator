//////////////////////////////////////////////////
// A recursive descent parser and evaluator for //
// a grammar used in simple calculator.         //
//////////////////////////////////////////////////

/*
Grammar:
<uint_par> = UINT | "(" <expr> ")"
<un_minus> = ["-"], <uint_par>  // also `factor`
<bin_mul_div> = <un_minus> { ("*" | "/") } <un_minus>
<bin_add_sub> = <bin_mul_div> { ("+" | "-") } <bin_mul_div>
<expr> = <bin_add_sub>
*/


// Note: These should be ordered in ascending order
// depending on their ASCII value.
// Obviously, you shoud not merge tokens and characters
// to avoid such situations.
enum TOK {
    EOF,
    INT,
    NAME,
    MUL = '*',
    LPAR = '(',
    RPAR = ')',
    ADD = '+',
    SUB = '-',
    DIV = '/',
    __LAST = DIV
};

immutable const(char)*[] token_names = [
    TOK.EOF:  "End of File",
    TOK.INT:  "int constant",
    TOK.NAME: "name",
    TOK.MUL:  "*",
    TOK.LPAR: "(",
    TOK.RPAR: ")",
    TOK.ADD:  "+",
    TOK.SUB:  "-",
    TOK.DIV:  "/"
];

struct Token {
    TOK kind;
    // `start`, `end` if you want
    // to keep the text repr. around
    int val;
};

enum { DEC = 0b1, MIDCHAR = 0b10, WHITE = 0b100 };

immutable charmap = () {
    ubyte[256] table;
    foreach (const c; 0 .. table.length)
    {
        if ('0' <= c && c <= '9') {
            table[c] |= DEC;
        }
        
        switch(c) {
        case ' ':
        case '\t':
        case '\n':
        case '\r':
            table[c] |= WHITE;
            break;
        case 'A': .. case 'Z':
        case 'a': .. case 'z':
        case '_':
            table[c] |= MIDCHAR;
            break;
        default:
        }
    }
    return table;
}();

enum PREC { __INIT, LOWEST, ADD, MUL, FACTOR };

immutable prec = () {
    import std.traits;
    enum TOK_length = TOK.__LAST - TOK.EOF + 1;
    PREC[TOK_length] table;

    table[TOK.ADD] = PREC.ADD;
    table[TOK.SUB] = PREC.ADD;

    table[TOK.MUL] = PREC.MUL;
    table[TOK.DIV] = PREC.MUL;

    return table;
}();

Token token;
const(char)* stream;

@nogc:
nothrow:

private:

import core.stdc.stdio : printf;

void _log(string s) {
    printf("%s", s.ptr);
}

void _log(const(char) *s) {
    printf("%s", s);
}

void _log(TOK kind) {
    print_token(kind);
}

void log(A...)(A a)
{
	static foreach(t; a){
		_log(t);
	}
    printf("\n");
}

void print_token(TOK kind) {
    printf("\x1b[1m");  // bold on
    printf("`%s`", token_names[kind]);
    printf("\033[0m");  // bold off
}

// Put the next token to the global 'token'
void next_token() {
    // skip whitespace
    while (charmap[*stream] & WHITE) {
        stream++;
    }

    switch (*stream) {
    // integer
    case '0': .. case '9':
    {
        int val = 0;
        // no test for overflow...
        while (charmap[*stream] & DEC) {
            val = val * 10 + *stream - '0';
            ++stream;
        }
        token.kind = TOK.INT;
        token.val = val;
    } break;
    
    // name
    case 'A': .. case 'Z':
    case 'a': .. case 'z':
    case '_':
    {
        while (charmap[*stream] & MIDCHAR) {
            ++stream;
        }
        token.kind = TOK.NAME;
    } break;

    default:
        token.kind = cast(TOK)*stream;
        ++stream;
    }
}

bool is_token(TOK kind) {
    return token.kind == kind;
}

bool match_token(TOK kind) {
    if (is_token(kind)) {
        next_token();
        return true;
    }
    else {
        return false;
    }
}

void expect_token(TOK kind) {
    if (is_token(kind)) {
        next_token();
    } else {
        log("Expected ", kind, ", got ", token.kind);
    }
}

int parse_uint_par() {
    int val;
    if (is_token(TOK.INT)) {
        val = token.val;
        next_token();
    } else if (match_token(TOK.LPAR)) {
        val = parse_expr();
        expect_token(TOK.RPAR);
    } else {
        log("Expected integer constant or `(`, got: ", token.kind);
        // One can go this one step further and create a `skip_tokens`
        // function that will skip tokens until it finds one that
        // that starts a <uint_par>
    }
    return val;
}

int parse_un_minus() {
    if (is_token(TOK.SUB)) {
        next_token();
        return -parse_uint_par();
    }
    return parse_uint_par();
}

auto get_op_func(TOK op)
{
    switch (op) {
        case TOK.ADD: return (int l, int r) => l + r;
        case TOK.SUB: return (int l, int r) => l - r;
        case TOK.MUL: return (int l, int r) => l * r;
        case TOK.DIV: return (int l, int r) => l / r;
        default: assert(0, "Unexpected operator");
    }
}

// Since all binary expressions have the same pattern,
// we do something even simpler than the previous version
// which is we track the operator precedence in a table.
// Then, we can parse_bin() again as the "higher_prec_function"
// with incremented precedence.
// This is based on the precedence climbing technique.
int parse_bin(int precedence) {
    if (precedence == PREC.FACTOR) {
        return parse_un_minus();
    }
    int val = parse_bin(precedence + 1);
    while (prec[token.kind] == precedence) {
        TOK op = token.kind;
        next_token();
        int rval = parse_bin(precedence + 1);
        val = get_op_func(op)(val, rval);
    }
    return val;
}

int parse_expr() {
    return parse_bin(PREC.LOWEST);
}

void assert_expr(string expr)() {
    stream = expr.ptr;
    next_token();
    int res = parse_expr();
    // `mixin` is cool to use here
    // but since we want to have exprs
    // with errors, the `mixin` will catch them.
    //assert(res == mixin(expr));
    expect_token(TOK.EOF);
}

void main() {
    assert_expr!(q{1 + 2})();
    assert_expr!(q{(1 + 2 + 3})();  // error
    assert_expr!(q{3})();
    assert_expr!(q{4)})();
    assert_expr!(q{1 - 2 - 3})();
    assert_expr!(q{2 * 3 + 4 * 5})();
    assert_expr!(q{2 + -3})();
    assert_expr!(q{2 * (3 + 4) * 5})();
    assert_expr!(q{4 / 2})();
}
