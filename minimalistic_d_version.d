//////////////////////////////////////////////////
// A recursive descent parser and evaluator for //
// a grammar used in simple calculator.         //
//////////////////////////////////////////////////

/*
Grammar:
<uint_par> = UINT | "(" <expr> ")"
<un_minus> = ["-"], <uint_par>
<bin_mul_div> = <un_minus> { ("*" | "/") } <un_minus>
<bin_add_sub> = <bin_mul_div> { ("+" | "-") } <bin_mul_div>
<expr> = <bin_add_sub>
*/

enum TOK {
    EOF,
    INT,
    NAME,
    ADD = '+',
    SUB = '-',
    MUL = '*',
    DIV = '/',
    LPAR = '(',
    RPAR = ')',
};

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

Token token;
const(char)* stream;

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

bool expect_token(TOK kind) {
    if (is_token(kind)) {
        next_token();
        return true;
    }
    assert(0);
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
        assert(0, "Expected integer constant or `(`, got: ");
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

// NOTE(stefanos): A sort of functional style, with higher-order functions.
// Call a higher precedence function to parse the lhs. Then
// possibly parse a binary operator. Parse the rhs. Based on the op,
// take the appropriate lambda and call it to get a val.
int parse_bin(int function() parse_higher_prec_expr, TOK[] ops) {
    import std.algorithm : canFind;
    int val = parse_higher_prec_expr();
    while (ops.canFind(token.kind)) {
        TOK op = token.kind;
        next_token();
        int rval = parse_higher_prec_expr();
        val = get_op_func(op)(val, rval);
    }
    return val;
}

int parse_bin_mul_add() {
    TOK[] ops = [ TOK.MUL, TOK.DIV ];
    return parse_bin(&parse_un_minus, ops);
}

int parse_bin_add_sub() {
    TOK[] ops = [ TOK.ADD, TOK.SUB ];
    return parse_bin(&parse_bin_mul_add, ops);
}

int parse_expr() {
    return parse_bin_add_sub();
}

void assert_expr(string expr)() {
    stream = expr.ptr;
    next_token();
    int res = parse_expr();
    assert(res == mixin(expr));
    assert(token.kind == TOK.EOF);
}

void main() {
    assert_expr!(q{1 + 2})();
    assert_expr!(q{(1 + 2) + 3})();
    assert_expr!(q{3})();
    assert_expr!(q{(4)})();
    assert_expr!(q{1 - 2 - 3})();
    assert_expr!(q{2 * 3 + 4 * 5})();
    assert_expr!(q{2 + -3})();
    assert_expr!(q{2 * (3 + 4) * 5})();
    assert_expr!(q{4 / 2})();
}
