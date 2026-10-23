fmt := std::fmt
vec := alloc::vec

sum_to := fn(in out ar : Arena, n : u64) -> u64 {
  mut sum : u64 = 0
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
  sum
}

_start := fn() {
  match std::os::arena(81000000) {
    Result::Ok(osar) => {
      mut ar := osar.region()
      sum : u64 = sum_to(ar, 10000000)
      fmt::print("sum = {}\n", sum)
      fa := std::os::free(osar)
    }
    Result::Err(e) => { panic("arraysum: cannot map the arena") }
  }
  exit(0)
}
