#include <stdbool.h>
#include <stdio.h>

#define LIMIT 1000000UL

static bool is_prime(unsigned long n) {
    if (n < 2) {
        return false;
    }
    for (unsigned long j = 2; j * j <= n; j++) {
        if (n % j == 0) {
            return false;
        }
    }
    return true;
}

int main(void) {
    unsigned long count = 0;
    for (unsigned long i = 2; i < LIMIT; i++) {
        if (is_prime(i)) {
            count++;
        }
    }
    printf("primes = %lu\n", count);
    return 0;
}
