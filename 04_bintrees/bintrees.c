#include <stdio.h>
#include <stdlib.h>

#define MIN_DEPTH 4
#define MAX_DEPTH 17

typedef struct Node {
    struct Node *left;
    struct Node *right;
} Node;

static Node *bottom_up(int depth) {
    Node *node = malloc(sizeof(Node));
    if (depth > 0) {
        node->left = bottom_up(depth - 1);
        node->right = bottom_up(depth - 1);
    } else {
        node->left = NULL;
        node->right = NULL;
    }
    return node;
}

static long check(const Node *node) {
    if (node->left == NULL) {
        return 1;
    }
    return 1 + check(node->left) + check(node->right);
}

static void delete_tree(Node *node) {
    if (node->left != NULL) {
        delete_tree(node->left);
        delete_tree(node->right);
    }
    free(node);
}

int main(void) {
    int stretch_depth = MAX_DEPTH + 1;
    Node *stretch = bottom_up(stretch_depth);
    printf("stretch tree of depth %d check %ld\n", stretch_depth, check(stretch));
    delete_tree(stretch);

    Node *long_lived = bottom_up(MAX_DEPTH);
    for (int depth = MIN_DEPTH; depth <= MAX_DEPTH; depth += 2) {
        long iterations = 1L << (MAX_DEPTH - depth + MIN_DEPTH);
        long total = 0;
        for (long i = 0; i < iterations; i++) {
            Node *tree = bottom_up(depth);
            total += check(tree);
            delete_tree(tree);
        }
        printf("%ld trees of depth %d check %ld\n", iterations, depth, total);
    }
    printf("long lived tree of depth %d check %ld\n", MAX_DEPTH, check(long_lived));
    delete_tree(long_lived);
    return 0;
}
