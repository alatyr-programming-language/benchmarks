MIN_DEPTH = 4
MAX_DEPTH = 17


def bottom_up(depth):
    if depth == 0:
        return (None, None)
    return (bottom_up(depth - 1), bottom_up(depth - 1))


def check(node):
    left, right = node
    if left is None:
        return 1
    return 1 + check(left) + check(right)


def main():
    stretch_depth = MAX_DEPTH + 1
    print(f"stretch tree of depth {stretch_depth} check {check(bottom_up(stretch_depth))}")

    long_lived = bottom_up(MAX_DEPTH)
    for depth in range(MIN_DEPTH, MAX_DEPTH + 1, 2):
        iterations = 1 << (MAX_DEPTH - depth + MIN_DEPTH)
        total = sum(check(bottom_up(depth)) for _ in range(iterations))
        print(f"{iterations} trees of depth {depth} check {total}")
    print(f"long lived tree of depth {MAX_DEPTH} check {check(long_lived)}")


main()
