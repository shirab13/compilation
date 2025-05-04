// symtab.c
#include "symtable.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define MAX_FUNCTIONS 100

typedef struct {
    char name[64];
    char return_type[16];
    int param_count;
} Function;

static Function function_table[MAX_FUNCTIONS];
static int function_count = 0;

void declare_function(const char* name, const char* return_type, int param_count) {
    if (function_count >= MAX_FUNCTIONS) {
        fprintf(stderr, "Function table overflow\n");
        return;
    }
    strncpy(function_table[function_count].name, name, 63);
    strncpy(function_table[function_count].return_type, return_type, 15);
    function_table[function_count].param_count = param_count;
    function_count++;
}

bool validate_main_function() {
    int main_count = 0;
    for (int i = 0; i < function_count; i++) {
        if (strcmp(function_table[i].name, "_main_") == 0) {
            main_count++;
            if (function_table[i].param_count != 0) {
                fprintf(stderr, "Semantic error: _main_ must not take parameters\n");
                return false;
            }
            if (strcmp(function_table[i].return_type, "void") != 0) {
                fprintf(stderr, "Semantic error: _main_ must return void\n");
                return false;
            }
        }
    }
    if (main_count == 0) {
        fprintf(stderr, "Semantic error: _main_ function is missing\n");
        return false;
    }
    if (main_count > 1) {
        fprintf(stderr, "Semantic error: _main_ function declared more than once\n");
        return false;
    }
    return true;
}
