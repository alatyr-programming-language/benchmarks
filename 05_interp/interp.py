MASK = 0xFFFFF
MAX_DEPTH = 12
RUNS = 40_000

CONST, VAR, ADD, SUB, MUL, LT, IF = range(7)


class Gen:
    def __init__(self, seed):
        self.state = seed
        self.program = []

    def next(self):
        self.state = self.state * 48271 % 2147483647
        return self.state

    def gen(self, depth):
        r = self.next() % 10
        if depth == 0 or r < 2:
            if self.next() % 2 == 0:
                expr = (CONST, self.next() % 100)
            else:
                expr = (VAR, self.next() % 4)
        elif r < 8:
            lhs = self.gen(depth - 1)
            rhs = self.gen(depth - 1)
            op = ADD if r < 4 else SUB if r < 5 else MUL if r < 7 else LT
            expr = (op, lhs, rhs)
        else:
            cond = self.gen(depth - 1)
            then = self.gen(depth - 1)
            other = self.gen(depth - 1)
            expr = (IF, cond, then, other)
        self.program.append(expr)
        return len(self.program) - 1


def evaluate(program, i, vars):
    e = program[i]
    op = e[0]
    if op == CONST:
        return e[1]
    if op == VAR:
        return vars[e[1]]
    if op == ADD:
        return (evaluate(program, e[1], vars) + evaluate(program, e[2], vars)) & MASK
    if op == SUB:
        return (evaluate(program, e[1], vars) + MASK + 1 - evaluate(program, e[2], vars)) & MASK
    if op == MUL:
        return (evaluate(program, e[1], vars) * evaluate(program, e[2], vars)) & MASK
    if op == LT:
        return 1 if evaluate(program, e[1], vars) < evaluate(program, e[2], vars) else 0
    if evaluate(program, e[1], vars) != 0:
        return evaluate(program, e[2], vars)
    return evaluate(program, e[3], vars)


def main():
    g = Gen(42)
    root = g.gen(MAX_DEPTH)
    total = 0
    for run in range(RUNS):
        vars = [(run * (2 * k + 3) + k) & MASK for k in range(4)]
        total += evaluate(g.program, root, vars)
    print(f"nodes = {len(g.program)} checksum = {total}")


main()
