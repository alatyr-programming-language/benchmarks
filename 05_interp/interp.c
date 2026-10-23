#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MASK 0xFFFFFu
#define MAX_DEPTH 12
#define RUNS 40000

typedef enum { CONST, VAR, ADD, SUB, MUL, LT, IF } Kind;

typedef struct {
    Kind kind;
    union {
        uint64_t value;
        uint32_t var;
        struct {
            uint32_t lhs, rhs;
        } bin;
        struct {
            uint32_t cond, then, other;
        } branch;
    } as;
} Expr;

typedef struct {
    Expr *nodes;
    uint32_t len, cap;
} Program;

static uint64_t rng_state = 42;

static uint64_t next(void) {
    rng_state = rng_state * 48271 % 2147483647;
    return rng_state;
}

static uint32_t push(Program *p, Expr e) {
    if (p->len == p->cap) {
        p->cap = p->cap ? p->cap * 2 : 64;
        p->nodes = realloc(p->nodes, p->cap * sizeof(Expr));
    }
    p->nodes[p->len] = e;
    return p->len++;
}

static uint32_t gen(Program *p, int depth) {
    uint64_t r = next() % 10;
    Expr e;
    if (depth == 0 || r < 2) {
        if (next() % 2 == 0) {
            e.kind = CONST;
            e.as.value = next() % 100;
        } else {
            e.kind = VAR;
            e.as.var = (uint32_t)(next() % 4);
        }
    } else if (r < 8) {
        e.kind = r < 4 ? ADD : r < 5 ? SUB : r < 7 ? MUL : LT;
        e.as.bin.lhs = gen(p, depth - 1);
        e.as.bin.rhs = gen(p, depth - 1);
    } else {
        e.kind = IF;
        e.as.branch.cond = gen(p, depth - 1);
        e.as.branch.then = gen(p, depth - 1);
        e.as.branch.other = gen(p, depth - 1);
    }
    return push(p, e);
}

static uint64_t eval(const Expr *nodes, uint32_t i, const uint64_t *vars) {
    const Expr *e = &nodes[i];
    switch (e->kind) {
    case CONST:
        return e->as.value;
    case VAR:
        return vars[e->as.var];
    case ADD:
        return (eval(nodes, e->as.bin.lhs, vars) + eval(nodes, e->as.bin.rhs, vars)) & MASK;
    case SUB:
        return (eval(nodes, e->as.bin.lhs, vars) + MASK + 1 - eval(nodes, e->as.bin.rhs, vars)) & MASK;
    case MUL:
        return (eval(nodes, e->as.bin.lhs, vars) * eval(nodes, e->as.bin.rhs, vars)) & MASK;
    case LT:
        return eval(nodes, e->as.bin.lhs, vars) < eval(nodes, e->as.bin.rhs, vars);
    case IF:
        if (eval(nodes, e->as.branch.cond, vars) != 0) {
            return eval(nodes, e->as.branch.then, vars);
        }
        return eval(nodes, e->as.branch.other, vars);
    }
    abort();
}

int main(void) {
    Program p = {NULL, 0, 0};
    uint32_t root = gen(&p, MAX_DEPTH);
    uint64_t vars[4];
    uint64_t total = 0;
    for (uint64_t run = 0; run < RUNS; run++) {
        for (uint64_t k = 0; k < 4; k++) {
            vars[k] = (run * (2 * k + 3) + k) & MASK;
        }
        total += eval(p.nodes, root, vars);
    }
    printf("nodes = %" PRIu32 " checksum = %" PRIu64 "\n", p.len, total);
    free(p.nodes);
    return 0;
}
