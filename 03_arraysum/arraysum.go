package main

import "fmt"

const N = 10_000_000

func main() {
	a := make([]uint64, N)
	for i := uint64(0); i < N; i++ {
		a[i] = i
	}
	var sum uint64 = 0
	for _, x := range a {
		sum += x
	}
	fmt.Printf("sum = %d\n", sum)
}
