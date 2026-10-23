package main

import "fmt"

const (
	MinDepth = 4
	MaxDepth = 17
)

type Node struct {
	left, right *Node
}

func bottomUp(depth int) *Node {
	if depth == 0 {
		return &Node{}
	}
	return &Node{bottomUp(depth - 1), bottomUp(depth - 1)}
}

func (n *Node) check() int {
	if n.left == nil {
		return 1
	}
	return 1 + n.left.check() + n.right.check()
}

func main() {
	stretchDepth := MaxDepth + 1
	fmt.Printf("stretch tree of depth %d check %d\n", stretchDepth, bottomUp(stretchDepth).check())

	longLived := bottomUp(MaxDepth)
	for depth := MinDepth; depth <= MaxDepth; depth += 2 {
		iterations := 1 << (MaxDepth - depth + MinDepth)
		total := 0
		for i := 0; i < iterations; i++ {
			total += bottomUp(depth).check()
		}
		fmt.Printf("%d trees of depth %d check %d\n", iterations, depth, total)
	}
	fmt.Printf("long lived tree of depth %d check %d\n", MaxDepth, longLived.check())
}
