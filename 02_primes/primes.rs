const LIMIT: u64 = 1_000_000;

fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    let mut j = 2u64;
    while j * j <= n {
        if n % j == 0 {
            return false;
        }
        j += 1;
    }
    true
}

fn main() {
    let mut count = 0u64;
    let mut i = 2u64;
    while i < LIMIT {
        if is_prime(i) {
            count += 1;
        }
        i += 1;
    }
    println!("primes = {}", count);
}
