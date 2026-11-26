package main

import "fmt"

const (
	Mask     = 0xFFFFF
	MaxDepth = 12
	Runs     = 40_000
)

type Kind uint8

const (
	Const Kind = iota
	Var
	Add
	Sub
	Mul
	Lt
	If
)

type Expr struct {
	kind    Kind
	value   uint64
	a, b, c int
}

type Gen struct {
	state   uint64
	program []Expr
}

func (g *Gen) next() uint64 {
	g.state = g.state * 48271 % 2147483647
	return g.state
}

func (g *Gen) gen(depth int) int {
	r := g.next() % 10
	var e Expr
	switch {
	case depth == 0 || r < 2:
		if g.next()%2 == 0 {
			e = Expr{kind: Const, value: g.next() % 100}
		} else {
			e = Expr{kind: Var, a: int(g.next() % 4)}
		}
	case r < 8:
		lhs := g.gen(depth - 1)
		rhs := g.gen(depth - 1)
		kind := Lt
		switch r {
		case 2, 3:
			kind = Add
		case 4:
			kind = Sub
		case 5, 6:
			kind = Mul
		}
		e = Expr{kind: kind, a: lhs, b: rhs}
	default:
		cond := g.gen(depth - 1)
		then := g.gen(depth - 1)
		other := g.gen(depth - 1)
		e = Expr{kind: If, a: cond, b: then, c: other}
	}
	g.program = append(g.program, e)
	return len(g.program) - 1
}

func eval(program []Expr, i int, vars *[4]uint64) uint64 {
	e := &program[i]
	switch e.kind {
	case Const:
		return e.value
	case Var:
		return vars[e.a]
	case Add:
		return (eval(program, e.a, vars) + eval(program, e.b, vars)) & Mask
	case Sub:
		return (eval(program, e.a, vars) + Mask + 1 - eval(program, e.b, vars)) & Mask
	case Mul:
		return (eval(program, e.a, vars) * eval(program, e.b, vars)) & Mask
	case Lt:
		if eval(program, e.a, vars) < eval(program, e.b, vars) {
			return 1
		}
		return 0
	default:
		if eval(program, e.a, vars) != 0 {
			return eval(program, e.b, vars)
		}
		return eval(program, e.c, vars)
	}
}

func main() {
	g := Gen{state: 42}
	root := g.gen(MaxDepth)
	var vars [4]uint64
	var total uint64
	for run := uint64(0); run < Runs; run++ {
		for k := range vars {
			vars[k] = (run*uint64(2*k+3) + uint64(k)) & Mask
		}
		total += eval(g.program, root, &vars)
	}
	fmt.Printf("nodes = %d checksum = %d\n", len(g.program), total)
}
