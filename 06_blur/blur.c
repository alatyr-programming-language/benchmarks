#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define W 1024
#define H 1024
#define PASSES 100

static void blur(const uint32_t *src, uint32_t *dst) {
    for (int y = 0; y < H; y++) {
        int y0 = y > 0 ? y - 1 : 0;
        int y1 = y < H - 1 ? y + 1 : H - 1;
        for (int x = 0; x < W; x++) {
            int x0 = x > 0 ? x - 1 : 0;
            int x1 = x < W - 1 ? x + 1 : W - 1;
            uint32_t sum = src[y0 * W + x0] + src[y0 * W + x] + src[y0 * W + x1]
                         + src[y * W + x0] + src[y * W + x] + src[y * W + x1]
                         + src[y1 * W + x0] + src[y1 * W + x] + src[y1 * W + x1];
            dst[y * W + x] = sum / 9;
        }
    }
}

int main(void) {
    uint32_t *a = malloc(W * H * sizeof(uint32_t));
    uint32_t *b = malloc(W * H * sizeof(uint32_t));
    uint64_t state = 42;
    for (int i = 0; i < W * H; i++) {
        state = state * 48271 % 2147483647;
        a[i] = (uint32_t)(state % 256);
    }
    for (int pass = 0; pass < PASSES; pass++) {
        blur(a, b);
        uint32_t *t = a;
        a = b;
        b = t;
    }
    uint64_t sum = 0;
    for (int i = 0; i < W * H; i++) {
        sum += a[i];
    }
    printf("sum = %" PRIu64 "\n", sum);
    free(a);
    free(b);
    return 0;
}
