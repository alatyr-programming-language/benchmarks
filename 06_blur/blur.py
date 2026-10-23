W = 1024
H = 1024
PASSES = 100


def blur(src, dst):
    for y in range(H):
        r0 = max(y - 1, 0) * W
        r1 = y * W
        r2 = min(y + 1, H - 1) * W
        for x in range(W):
            x0 = x - 1 if x > 0 else 0
            x1 = x + 1 if x < W - 1 else W - 1
            total = (src[r0 + x0] + src[r0 + x] + src[r0 + x1]
                     + src[r1 + x0] + src[r1 + x] + src[r1 + x1]
                     + src[r2 + x0] + src[r2 + x] + src[r2 + x1])
            dst[r1 + x] = total // 9


def main():
    state = 42
    a = []
    for _ in range(W * H):
        state = state * 48271 % 2147483647
        a.append(state % 256)
    b = [0] * (W * H)
    for _ in range(PASSES):
        blur(a, b)
        a, b = b, a
    print(f"sum = {sum(a)}")


main()
