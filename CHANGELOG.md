# Changelog

Benchmark *results* are not versioned — they depend on the machine, and a number without its machine
is not a measurement. What is recorded here is what would make an old result incomparable to a new
one: a changed program, a changed toolchain pin, or a changed measurement method.

## Unreleased

- Three new cases, each in all ten languages: `04_bintrees` (allocation — Benchmarks Game
  binary-trees at depth 17; Alatyr frees each tree by closing its region), `05_interp`
  (dispatch — a tree-walking interpreter over a seeded 4,614-node program, 40,000 runs) and
  `06_blur` (checked indexing — a 3×3 box blur, 1024×1024, 100 passes; Alatyr keeps its default
  checked arithmetic and bounds checks, and stores `u64` pixels where the others store `u32`).
- `03_arraysum.al` handles the `Result` that `std::os::arena` now returns and fills the vector
  in a function that takes the arena as `in out` parameter; the measured loops are unchanged.

Split out of the compiler repository.

- The harness no longer builds a compiler. Resolution is `ALATYR`, then `alatyr` on `PATH`, then a
  hard error — previously it ran the compiler's bootstrap under `|| true`, which in a standalone
  checkout fails silently and dropped Alatyr from the table behind a `note:` on stderr.
- Own `flake.nix` with the nine comparison toolchains and GNU `time`, pinned to the same nixpkgs
  revision the compiler repository uses so the C column stays comparable across the two.
- Alatyr build and runtime failures are now hard errors; optional toolchain failures are reported
  as `-` with a note, and the runner checks the complete comparison toolchain before attempting a
  direnv re-exec.
- Correct benchmark documentation to match the `NN_name/` layout, the raw-startup/default-profile
  compiler invocation, and the current reference compiler's stdlib surface.
