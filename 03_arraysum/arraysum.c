#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define N 10000000

int main(void) {
    uint64_t *a = malloc(N * sizeof(uint64_t));
    for (uint64_t i = 0; i < N; i++) {
        a[i] = i;
    }
    uint64_t sum = 0;
    for (size_t i = 0; i < N; i++) {
        sum += a[i];
    }
    printf("sum = %" PRIu64 "\n", sum);
    free(a);
    return 0;
}
