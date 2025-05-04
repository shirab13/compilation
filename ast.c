#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

node* mknode(char* token, char* value, node* parent) {
    node* new_node = (node*)malloc(sizeof(node));
    new_node->token = strdup(token);

    if (value != NULL && strcmp(token, "CHARVAL") == 0) {
        // Wrap the character value in quotes if it's a CHARVAL
        char* quoted_value = (char*)malloc(strlen(value) + 3);  // Space for quotes
        quoted_value[0] = '\'';  // Add opening quote
        strcpy(quoted_value + 1, value);  // Copy the character
        quoted_value[strlen(value) + 1] = '\'';  // Add closing quote
        quoted_value[strlen(value) + 2] = '\0';  // Null-terminate
        new_node->value = quoted_value;  // Store the quoted value
    }
    else {
        new_node->value = value ? strdup(value) : NULL;
    }

    new_node->parent = parent;
    new_node->children_len = 0;
    new_node->children = NULL;
    fprintf(stderr, "Adding node: %s\n", token);
    return new_node;
}


node* wrapNode(char* token, node* child) {
    node* new_node = mknode(token, NULL, NULL);
    addSon(new_node, child);
    return new_node;
}

void addSon(node* parent, node* child) {
    if (child == NULL) return;
    parent->children_len++;
    parent->children = (node**)realloc(parent->children, parent->children_len * sizeof(node*));
    parent->children[parent->children_len - 1] = child;
}

void ptab(int tab, int eq) {
    int count = eq ? tab + 1 : tab;
    for (int i = 0; i < count; i++) printf("\t");
}

int is_all_children_leaf(node* n) {
    for (int i = 0; i < n->children_len; i++) {
        if (n->children[i]->children_len > 0)
            return 0;
    }
    return 1;
}
int is_operator_node(const char* token) {
    return strcmp(token, "+") == 0 || strcmp(token, "*") == 0 ||
        strcmp(token, "=") == 0 || strcmp(token, ">") == 0 ||
        strcmp(token, "<") == 0;
}
void printNode(node* n, int tab) {
    if (!n) return;

    // Skip STMTS
    if (strcmp(n->token, "STMTS") == 0) {
        for (int i = 0; i < n->children_len; i++) {
            printNode(n->children[i], tab);
        }
        return;
    }

    // If the token is a number and has a value, just print the value
    if (strcmp(n->token, "NUM") == 0 && n->value) {
        ptab(tab, 0);
        printf("%s\n", n->value);
        return;
    }

    // If the token is CHARVAL, print the value with single quotes around it
    if (strcmp(n->token, "CHARVAL") == 0 && n->value) {
        ptab(tab, 0);
        printf("'%s'\n", n->value);  // Print character with single quotes
        return;
    }

    // Single leaf node
    if (n->children_len == 0) {
        ptab(tab, 0);
        if (n->value)
            printf("(%s %s)\n", n->token, n->value);
        else
            printf("%s\n", n->token);
        return;
    }

    // "=" with first child being a leaf and second being a complex node
    if (strcmp(n->token, "=") == 0 &&
        n->children_len == 2 &&
        n->children[0]->children_len == 0 &&
        !n->children[0]->value &&
        (n->children[1]->children_len > 0 || n->children[1]->value)) {

        ptab(tab, 0);
        printf("(%s %s\n", n->token, n->children[0]->token);
        printNode(n->children[1], tab + 1);
        ptab(tab, 0);
        printf(")\n");
        return;
    }

    // "=" with two simple children
    if (strcmp(n->token, "=") == 0 &&
        n->children_len == 2 &&
        n->children[0]->children_len == 0 && !n->children[0]->value &&
        n->children[1]->children_len == 0 &&
        (n->children[1]->value || !n->children[1]->value)) {

        ptab(tab, 0);
        if (n->children[1]->value)
            printf("(%s %s %s)\n", n->token, n->children[0]->token, n->children[1]->value);
        else
            printf("(%s %s %s)\n", n->token, n->children[0]->token, n->children[1]->token);
        return;
    }

    // Operator node with leaves only (like > x y)
    if (is_all_children_leaf(n) && is_operator_node(n->token)) {
        ptab(tab, 0);
        printf("(%s", n->token);
        for (int i = 0; i < n->children_len; i++) {
            if (n->children[i]->value)
                printf(" %s", n->children[i]->value);
            else
                printf(" %s", n->children[i]->token);
        }
        printf(")\n");
        return;
    }

    // Regular printing
    ptab(tab, 0);
    printf("(%s", n->token);
    if (n->value)
        printf(" %s", n->value);
    printf("\n");

    for (int i = 0; i < n->children_len; i++) {
        printNode(n->children[i], tab + 1);
    }

    ptab(tab, 0);
    printf(")\n");
}


