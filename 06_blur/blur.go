package main

import "fmt"

const (
	W      = 1024
	H      = 1024
	Passes = 100
)

func blur(src, dst []uint32) {
	for y := 0; y < H; y++ {
		y0 := max(y-1, 0)
		y1 := min(y+1, H-1)
		for x := 0; x < W; x++ {
			x0 := max(x-1, 0)
			x1 := min(x+1, W-1)
			sum := src[y0*W+x0] + src[y0*W+x] + src[y0*W+x1] +
				src[y*W+x0] + src[y*W+x] + src[y*W+x1] +
				src[y1*W+x0] + src[y1*W+x] + src[y1*W+x1]
			dst[y*W+x] = sum / 9
		}
	}
}

func main() {
	a := make([]uint32, W*H)
	b := make([]uint32, W*H)
	state := uint64(42)
	for i := range a {
		state = state * 48271 % 2147483647
		a[i] = uint32(state % 256)
	}
	for pass := 0; pass < Passes; pass++ {
		blur(a, b)
		a, b = b, a
	}
	var sum uint64
	for _, p := range a {
		sum += uint64(p)
	}
	fmt.Printf("sum = %d\n", sum)
}
