<?php

const LIMIT = 1000000;

function is_prime(int $n): bool {
    if ($n < 2) {
        return false;
    }
    for ($j = 2; $j * $j <= $n; $j++) {
        if ($n % $j === 0) {
            return false;
        }
    }
    return true;
}

$count = 0;
for ($i = 2; $i < LIMIT; $i++) {
    if (is_prime($i)) {
        $count++;
    }
}
echo "primes = $count\n";
