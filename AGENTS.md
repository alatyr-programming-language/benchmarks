# AGENTS.md — the Alatyr benchmarks

Sixty programs — the same six algorithms written in ten languages — and `run.sh`, which builds,
times and compares them. No compiler lives here.

## What this repository is for, and what it is not for

It answers one question: **what does the same algorithm cost in Alatyr next to C, Rust, Zig, Go,
TypeScript, JavaScript, PHP, Ruby and Python** — wall time, compile time, peak RSS, artifact size,
source size.

It is **not** a gate. Timings on a shared or virtualised machine are noise, so nothing here may ever
become a pass/fail check. If you want a number to hold a decision, run it on a quiet machine, several
times, and say which machine.

## The one rule that matters

**A missing or failing Alatyr compiler/benchmark is a hard error, never a skipped column.** The
other nine toolchains are optional — a missing or failing one shows `-` and is skipped — but Alatyr
is not, and `run.sh` exits 2 with instructions when it cannot find or use one.

This is deliberate and it is the repository's history: the harness used to build the compiler itself
via `( cd .. && ./seed/alatyr build package.al ) || true`. Split out of the compiler tree, that
silently fails — and Alatyr then vanished from the table behind a one-line `note:` on stderr. A
comparison table missing the language it exists to measure still looks like a result. Refusing to
start is the honest failure.

So: never add a `|| true` to a build step, and never let a language be dropped without the table
saying so.

## Running it

```sh
nix develop                 # the nine comparison toolchains + GNU time
ALATYR=/path/to/alatyr ./run.sh          # everything
ALATYR=/path/to/alatyr ./run.sh 01_hello # one case
```

`direnv allow` also works — the harness re-execs itself under this repository's own shell when any
comparison toolchain or assembler/linker is absent from `PATH`.

Build a compiler from
[`compiler`](https://github.com/alatyr-programming-language/compiler):
`seed/alatyr build package.al` leaves it at `target/debug/alatyr`.

## The dev shell

`flake.nix` carries every comparison toolchain, and one entry is easy to mistake for optional:
**GNU `time`**. The harness reads peak RSS from `time -f '%e %M'`, so without it every `Mem` cell is
`-` — the measurements that motivate a systems language are exactly the ones that disappear quietly.
The Alatyr compiler is deliberately absent from that shell; see above.

`flake.lock` is pinned to the same nixpkgs revision the compiler repository uses, so the two shells
agree on `cc` and on the C library a build links against. If you bump one, bump both, or the C column
stops being comparable across repositories.

## Adding a benchmark

- One directory, `NN_name/`, one file per language, all named after the benchmark
  (`primes.al`, `primes.c`, …). `run.sh` finds the languages by extension.
- **Same algorithm, idiomatic in each language.** Not the same *code* transliterated — that measures
  translation, not the language. And not a different algorithm per language either, which measures
  nothing at all.
- **Print something derived from the whole computation.** The first language's output is the reference
  and a mismatch is flagged with `!`; a benchmark whose result is discarded invites the optimiser to
  delete the work, and then the fastest column is simply the best dead-code eliminator.
- Add every language you can, and say in `README.md` which are missing and why. A partly-filled row
  is fine; a silently partly-filled row is not.
