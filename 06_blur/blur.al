fmt := std::fmt
vec := alloc::vec

W : usize = 1024
H : usize = 1024
PASSES : u64 = 100

blur := fn(src : Slice(u32), dst : Slice(u32)) {
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

_start := fn() {
  mut mem := std::os::arena(2 * W * H * 4 + 4096).expect("blur: cannot map the image arena")
  mut ar := mem.region()
  mut total : u64 = 0
  alloc::with(ar) {
    mut a := vec::with_capacity(u32, W * H)
    mut b := vec::with_capacity(u32, W * H)
    mut state : u64 = 42
    mut i : usize = 0
    while i < W * H {
      state = state * 48271 % 2147483647
      # typed local: push(u32(..)) fails at link (compiler#445)
      px : u32 = u32(state % 256)
      a.push(px).expect("image arena")
      b.push(0).expect("image arena")
      i += 1
    }
    sa := vec::as_slice(u32, ptr(a))
    sb := vec::as_slice(u32, ptr(b))
    mut pass : u64 = 0
    while pass < PASSES {
      if pass % 2 == 0 {
        blur(sa, sb)
      } else {
        blur(sb, sa)
      }
      pass += 1
    }
    # indexed: `for p in a` over Vec(u32) reads a word per element (compiler#1925)
    mut j : usize = 0
    while j < W * H {
      total += u64(sa[j])
      j += 1
    }
    fb := b.free()
    fa := a.free()
  }
  fm := std::os::free(mem)
  fmt::print("sum = {}\n", total)
  exit(0)
}
