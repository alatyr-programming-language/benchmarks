LIMIT = 1_000_000


def is_prime(n):
    if n < 2:
        return False
    j = 2
    while j * j <= n:
        if n % j == 0:
            return False
        j += 1
    return True


def main():
    count = 0
    i = 2
    while i < LIMIT:
        if is_prime(i):
            count += 1
        i += 1
    print("primes =", count)


main()
