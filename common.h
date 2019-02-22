#pragma once

#include <assert.h>
#include <stdint.h>

#define global_variable static;

typedef uint8_t byte_t;
typedef int bool;
#define true 1
#define false 0

// First 127 kinds are the ASCII versions of the
// tokens.
typedef enum {
    TOKEN_UINT = 128,
    TOKEN_NAME,
    // ...
} TokenKind;

typedef struct {
    TokenKind kind;
    const char *start;
    const char *end;
    union {
        uint32_t val;
        const char *name;
    };
} Token;