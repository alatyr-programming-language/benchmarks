fmt := std::fmt

MASK : u64 = 1048575
MAX_DEPTH : u64 = 12
RUNS : u64 = 40000

Expr := enum {
  Const(u64),
  Var(usize),
  Add(Bin),
  Sub(Bin),
  Mul(Bin),
  Lt(Bin),
  If(Cond),
}
Bin := struct { lhs : Handle(Expr), rhs : Handle(Expr) }
Cond := struct { test : Handle(Expr), then : Handle(Expr), other : Handle(Expr) }

Gen := struct { state : u64, nodes : u64 }

next := fn(in out g : Gen) -> u64 {
  g.state = g.state * 48271 % 2147483647
  g.state
}

gen := fn(in out g : Gen, in out ar : Arena, depth : u64) -> Handle(Expr) {
  g.nodes += 1
  r := g.next() % 10
  if depth == 0 or r < 2 {
    if g.next() % 2 == 0 {
      @alloc(ar) leaf := Expr.Const(g.next() % 100)
      return leaf
    }
    @alloc(ar) var := Expr.Var(usize(g.next() % 4))
    return var
  }
  if r < 8 {
    lhs := gen(g, ar, depth - 1)
    rhs := gen(g, ar, depth - 1)
    b := Bin(lhs = lhs, rhs = rhs)
    if r < 4 {
      @alloc(ar) add := Expr.Add(b)
      return add
    }
    if r < 5 {
      @alloc(ar) sub := Expr.Sub(b)
      return sub
    }
    if r < 7 {
      @alloc(ar) mul := Expr.Mul(b)
      return mul
    }
    @alloc(ar) lt := Expr.Lt(b)
    return lt
  }
  test := gen(g, ar, depth - 1)
  then := gen(g, ar, depth - 1)
  other := gen(g, ar, depth - 1)
  @alloc(ar) branch := Expr.If(Cond(test = test, then = then, other = other))
  branch
}

eval := fn(ar : Arena, h : Handle(Expr), in vars : [u64; 4]) -> u64 {
  e : Expr = deref(get(Expr, ar, h))
  match e {
    Expr.Const(v) => v,
    Expr.Var(k) => vars[k],
    Expr.Add(b) => (eval(ar, b.lhs, vars) + eval(ar, b.rhs, vars)) & MASK,
    Expr.Sub(b) => (eval(ar, b.lhs, vars) + MASK + 1 - eval(ar, b.rhs, vars)) & MASK,
    Expr.Mul(b) => (eval(ar, b.lhs, vars) * eval(ar, b.rhs, vars)) & MASK,
    Expr.Lt(b) => if eval(ar, b.lhs, vars) < eval(ar, b.rhs, vars) { 1 } else { 0 },
    Expr.If(c) => if eval(ar, c.test, vars) != 0 { eval(ar, c.then, vars) } else { eval(ar, c.other, vars) },
  }
}

run := fn(in out ar : Arena) {
  mut g := Gen(state = 42, nodes = 0)
  root := gen(g, ar, MAX_DEPTH)
  mut vars : [u64; 4] = [0, 0, 0, 0]
  mut total : u64 = 0
  mut i : u64 = 0
  while i < RUNS {
    mut k : u64 = 0
    while k < 4 {
      vars[k] = (i * (2 * k + 3) + k) & MASK
      k += 1
    }
    total += eval(ar, root, vars)
    i += 1
  }
  fmt::print("nodes = {} checksum = {}\n", g.nodes, total)
  ar.close()
}

_start := fn() {
  match std::os::arena(1024 * 1024) {
    Result::Ok(mem) => {
      mut ar := mem.region()
      run(ar)
      fm := std::os::free(mem)
    }
    Result::Err(e) => { panic("interp: cannot map the program arena") }
  }
  exit(0)
}
