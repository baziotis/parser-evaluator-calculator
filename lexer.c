#include <ctype.h>
#include <inttypes.h>
#include <stdio.h>
#include "common.h"

Token token;
const char *stream;

// Put the next token to the global 'token'
void next_token(void) {
    // skip whitespace
    while (isspace(*stream)) stream++;

    // Big switch so that the compiler creates a
    // jump table.
    // NOTE(stefanos): With GCC case ranges, this function
    // can be a lot smaller.
    token.start = stream;
    switch (*stream) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    {
        uint32_t val = 0;
        while (isdigit(*stream)) {
            val = val * 10 + *stream - '0';
            ++stream;
        }
        token.kind = TOKEN_UINT;
        token.val = val;
        break;
    }

    case 'A':
    case 'B':
    case 'C':
    case 'D':
    case 'E':
    case 'F':
    case 'G':
    case 'H':
    case 'I':
    case 'J':
    case 'K':
    case 'L':
    case 'M':
    case 'N':
    case 'O':
    case 'P':
    case 'Q':
    case 'R':
    case 'S':
    case 'T':
    case 'U':
    case 'V':
    case 'W':
    case 'X':
    case 'Y':
    case 'Z':
    case 'a':
    case 'b':
    case 'c':
    case 'd':
    case 'e':
    case 'f':
    case 'g':
    case 'h':
    case 'i':
    case 'j':
    case 'k':
    case 'l':
    case 'm':
    case 'n':
    case 'o':
    case 'p':
    case 'q':
    case 'r':
    case 's':
    case 't':
    case 'u':
    case 'v':
    case 'w':
    case 'x':
    case 'y':
    case 'z':
    case '_':
    {
        while (isalnum(*stream) || *stream == '_') {
            ++stream;
        }
        token.kind = TOKEN_NAME;
        break;
    }

    default:
        token.kind = *stream++;
        break;
    }
    token.end = stream;
}

void print_token(Token token) {
    switch (token.kind) {
    case TOKEN_UINT:
    {
        printf("TOKEN_UINT: %" PRIu32 "\n", token.val);
        break;
    }
    case TOKEN_NAME:
    {
        printf("TOKEN_NAME: %.*s\n", (int)(token.end - token.start), token.start);
        break;
    }
    default:
        printf("TOKEN: %c\n", token.kind);
        break;
    }
}