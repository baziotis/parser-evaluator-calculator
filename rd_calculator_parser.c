#define _CRT_SECURE_NO_WARNINGS
#include "common.h"

//////////////////////////////////////////////////
// A recursive descent parser and evaluator for //
// a grammar used in simple calculator.         //
//////////////////////////////////////////////////

// Global variables used by lexer
extern Token token;
extern const char *stream;

/*
Grammar:
<uint_par> = UINT | "(" <expr> ")"
<un_minus> = ["-"], <uint_par>
<bin_mul_div> = <un_minus> { ("*" | "/") } <un_minus>
<bin_add_sub> = <bin_mul_div> { ("+" | "-") } <bin_mul_div>
<expr> = <bin_add_sub>
*/

// TODO(stefanos): token_kind_name.

//////////// UTILITY FUNCTIONS ////////////
bool is_token(TokenKind kind) {
    return token.kind == kind;
}

bool match_token(TokenKind kind) {
    if (is_token(kind)) {
        next_token();
        return true;
    }
    else {
        return false;
    }
}

bool expect_token(TokenKind kind) {
    if (is_token(kind)) {
        next_token();
        return true;
    }
    else {
        exit(1);
        return false;
    }
}

void init_stream(const char *s) {
    stream = s;
    next_token();
}

//////////// MAIN PARSING ROUTINES ////////////

int parse_expr(void);

int parse_uint_par(void) {
    int val;
    if (is_token(TOKEN_UINT)) {
        val = token.val;
        next_token();
    } else if (match_token('(')) {
        val = parse_expr();
        expect_token(')');
    }
    else {
        fatal("Expected UINT or (\n");
    }
    return val;
}

int parse_un_minus(void) {
    if (is_token('-')) {
        next_token();
        return -parse_uint_par();
    }
    return parse_uint_par();
}

bool token_is_one_of(TokenKind kinds[], size_t num_tokens) {
    for (size_t i = 0; i != num_tokens; ++i) {
        if (is_token(kinds[i])) return true;
    }
    return false;
}

// IMPORTANT(stefanos): GCC-ONLY!!!!!!
// return the operator function depending on the operator
int apply_op(char op, int l, int r) {
    asm("movl %0, %%ebx;" : : "l" (l));
    switch (op) {
        case '+': asm("addl %0, %%ebx; movl %%ebx, %%eax;" : : "r" (r)); break;
        case '-': asm("subl %0, %%ebx; movl %%ebx, %%eax;" : : "r" (r)); break;
        case '*': asm("imul %0, %%ebx; movl %%ebx, %%eax;" : : "r" (r)); break;
        default: asm("movl %0, %%ecx; movl %%ebx, %%eax; cdq; idiv %%ecx;" : : "r" (r));
    }
}


// NOTE(stefanos): A sort of functional style, with higher-order functions.
// Every binary expression has the same form, i.e. parse the left part, then possibly a
// binary operator and then a right part, where left and right parts are expressions
// of higher precedence.
int parse_bin(int(*parse_higher_prec_expr)(void), TokenKind ops[], size_t num_ops) {
    int val = parse_higher_prec_expr();
    while (token_is_one_of(ops, num_ops)) {
        char op = token.kind;
        next_token();
        int rval = parse_higher_prec_expr();
        val = apply_op(op, val, rval);
    }
    return val;
}

int parse_bin_mul_add(void) {
    TokenKind ops[] = { '*', '/' };
    return parse_bin(parse_un_minus, ops, sizeof(ops) / sizeof(ops[0]));
}

int parse_bin_add_sub(void) {
    TokenKind ops[] = { '+', '-' };
    return parse_bin(parse_bin_mul_add, ops, sizeof(ops) / sizeof(ops[0]));
}

int parse_expr(void) {
    return parse_bin_add_sub();
}

int parse_expr_str(const char *s) {
    init_stream(s);
    return parse_expr();
}

#define ASSERT_EXPR(expr) assert(parse_expr_str(#expr) == (expr))

int main(void) {
    ASSERT_EXPR(1 + 2);
    ASSERT_EXPR((1 + 2) + 3);
    ASSERT_EXPR(3);
    ASSERT_EXPR((4));
    ASSERT_EXPR(1 - 2 - 3);
    ASSERT_EXPR(2 * 3 + 4 * 5);
    ASSERT_EXPR(2 + -3);
    ASSERT_EXPR(2 * (3 + 4) * 5);
    ASSERT_EXPR(4 / 2);

    return 0;
}
