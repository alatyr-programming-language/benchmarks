fmt := std::fmt

MIN_DEPTH : u64 = 4
MAX_DEPTH : u64 = 17
ARENA_BYTES : usize = 64 * 1024 * 1024

Node := struct { children : Option(Children) }
Children := struct { left : Handle(Node), right : Handle(Node) }

bottom_up := fn(in out ar : Arena, depth : u64) -> Handle(Node) {
  if depth == 0 {
    @alloc(ar) leaf := Node(children = Option(Children).None)
    return leaf
  }
  l := bottom_up(ar, depth - 1)
  r := bottom_up(ar, depth - 1)
  @alloc(ar) node := Node(children = Option(Children).Some(Children(left = l, right = r)))
  node
}

check := fn(ar : Arena, h : Handle(Node)) -> u64 {
  node : Node = deref(get(Node, ar, h))
  children : Option(Children) = node.children
  match children {
    Some(c) => { return 1 + check(ar, c.left) + check(ar, c.right) }
    None => { return 1 }
  }
}

run := fn(in out long_ar : Arena, in out scratch : Arena, max_depth : u64) {
  stretch_depth := max_depth + 1
  stretch := bottom_up(scratch, stretch_depth)
  fmt::print("stretch tree of depth {} check {}\n", stretch_depth, check(scratch, stretch))
  scratch.close()

  long_lived := bottom_up(long_ar, max_depth)
  mut depth := MIN_DEPTH
  while depth <= max_depth {
    iterations := shl(u64(1), max_depth - depth + MIN_DEPTH)
    mut total : u64 = 0
    mut i : u64 = 0
    while i < iterations {
      tree := bottom_up(scratch, depth)
      total += check(scratch, tree)
      scratch.close()
      i += 1
    }
    fmt::print("{} trees of depth {} check {}\n", iterations, depth, total)
    depth += 2
  }
  fmt::print("long lived tree of depth {} check {}\n", max_depth, check(long_ar, long_lived))
  long_ar.close()
}

_start := fn() {
  match std::os::arena(ARENA_BYTES) {
    Result::Ok(long_mem) => {
      match std::os::arena(ARENA_BYTES) {
        Result::Ok(scratch_mem) => {
          mut long_ar := long_mem.region()
          mut scratch := scratch_mem.region()
          run(long_ar, scratch, MAX_DEPTH)
          fs := std::os::free(scratch_mem)
        }
        Result::Err(e) => { panic("bintrees: cannot map the scratch arena") }
      }
      fl := std::os::free(long_mem)
    }
    Result::Err(e) => { panic("bintrees: cannot map the long-lived arena") }
  }
  exit(0)
}
