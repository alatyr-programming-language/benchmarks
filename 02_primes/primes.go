package main

import "fmt"

const LIMIT uint64 = 1_000_000

func isPrime(n uint64) bool {
	if n < 2 {
		return false
	}
	for j := uint64(2); j*j <= n; j++ {
		if n%j == 0 {
			return false
		}
	}
	return true
}

func main() {
	var count uint64 = 0
	for i := uint64(2); i < LIMIT; i++ {
		if isPrime(i) {
			count++
		}
	}
	fmt.Printf("primes = %d\n", count)
}
