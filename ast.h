#ifndef AST_H
#define AST_H

typedef struct node {
    char* token;
    char* value;
    struct node* parent;
    int children_len;
    struct node** children;
} node;

node* mknode(char* token, char* value, node* parent);
int is_all_children_leaf(node* n);
node* wrapNode(char* token, node* child);
void addSon(node* parent, node* child);
void printNode(node* n, int tab);
int is_operator_node(const char* token);
void ptab(int tab, int eq);

#endif
