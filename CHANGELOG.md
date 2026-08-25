# Changelog

Benchmark *results* are not versioned — they depend on the machine, and a number without its machine
is not a measurement. What is recorded here is what would make an old result incomparable to a new
one: a changed program, a changed toolchain pin, or a changed measurement method.

## Unreleased

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
