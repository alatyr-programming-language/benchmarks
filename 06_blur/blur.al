fmt := std::fmt
vec := alloc::vec

W : usize = 1024
H : usize = 1024
PASSES : u64 = 100

blur := fn(src : Slice(u64), dst : Slice(u64)) {
  mut y : usize = 0
  while y < H {
    y0 := if y > 0 { y - 1 } else { 0 }
    y1 := if y < H - 1 { y + 1 } else { H - 1 }
    mut x : usize = 0
    while x < W {
      x0 := if x > 0 { x - 1 } else { 0 }
      x1 := if x < W - 1 { x + 1 } else { W - 1 }
      sum := src[y0 * W + x0] + src[y0 * W + x] + src[y0 * W + x1]
        + src[y * W + x0] + src[y * W + x] + src[y * W + x1]
        + src[y1 * W + x0] + src[y1 * W + x] + src[y1 * W + x1]
      dst[y * W + x] = sum / 9
      x += 1
    }
    y += 1
  }
}

run := fn(in out ar : Arena) -> u64 {
  mut total : u64 = 0
  alloc::with(ar) {
    mut a := vec::with_capacity(u64, W * H)
    mut b := vec::with_capacity(u64, W * H)
    mut state : u64 = 42
    mut i : usize = 0
    while i < W * H {
      state = state * 48271 % 2147483647
      a.push(state % 256).expect("image arena")
      b.push(0).expect("image arena")
      i += 1
    }
    sa := vec::as_slice(u64, ptr(a))
    sb := vec::as_slice(u64, ptr(b))
    mut pass : u64 = 0
    while pass < PASSES {
      if pass % 2 == 0 {
        blur(sa, sb)
      } else {
        blur(sb, sa)
      }
      pass += 1
    }
    for p in a {
      total += p
    }
    fb := b.free()
    fa := a.free()
  }
  total
}

_start := fn() {
  match std::os::arena(2 * W * H * 8 + 4096) {
    Result::Ok(mem) => {
      mut ar := mem.region()
      total : u64 = run(ar)
      fmt::print("sum = {}\n", total)
      fm := std::os::free(mem)
    }
    Result::Err(e) => { panic("blur: cannot map the image arena") }
  }
  exit(0)
}
