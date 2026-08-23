fmt := std::fmt
vec := alloc::vec

_start := fn() {
  n : u64 = 10000000
  mut osar := std::os::arena(81000000)
  mut ar := osar.region()
  mut sum : u64 = 0
  ## Ambient allocator (D99): `vec::with_capacity` takes its arena from the enclosing
  ## `alloc::with(ar)` — no explicit `ptr(ar)` threading at the call.
  alloc::with(ar) {
    mut v := vec::with_capacity(u64, usize(n))
    mut i : u64 = 0
    unchecked {
      while i < n {
        r := v.push(i)
        i += 1
      }
    }
    unchecked {
      for x in v {
        sum += x
      }
    }
    f := v.free()
  }
  fa := std::os::free(osar)
  fmt::print("sum = {}\n", sum)
  exit(0)
}
