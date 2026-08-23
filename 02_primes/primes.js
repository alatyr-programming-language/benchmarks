const LIMIT = 1_000_000;

function isPrime(n) {
  if (n < 2) {
    return false;
  }
  let j = 2;
  while (j * j <= n) {
    if (n % j === 0) {
      return false;
    }
    j += 1;
  }
  return true;
}

let count = 0;
let i = 2;
while (i < LIMIT) {
  if (isPrime(i)) {
    count += 1;
  }
  i += 1;
}
console.log("primes =", count);
