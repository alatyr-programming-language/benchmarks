is_prime := fn(n : u64) -> bool {
  if n < 2 {
    return false
  }
  mut j : u64 = 2
  unchecked {
    while j * j <= n {
      if n % j == 0 {
        return false
      }
      j += 1
    }
  }
  true
}

_start := fn() {
  mut count : u64 = 0
  mut i : u64 = 2
  unchecked {
    while i < 1000000 {
      if is_prime(i) {
        count += 1
      }
      i += 1
    }
  }
  std::fmt::print("primes = {}\n", count)
  exit(0)
}
