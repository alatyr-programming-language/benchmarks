# Alatyr benchmarks

![license Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-green)
![requires a built compiler](https://img.shields.io/badge/requires-a%20built%20compiler-orange)

Cross-language micro-benchmarks comparing **Alatyr** against **C**, **Rust**,
**Zig**, **Go**, **TypeScript**, **JavaScript**, **PHP**, **Ruby**, and
**Python** on the *same* algorithm — measuring execution time, compile time, peak
memory, and artifact size.

## Running them

This repository holds only the benchmark programs. The compiler is not here and is not built here —
point `ALATYR` at a built one, or put `alatyr` on `PATH`:

```sh
git clone https://github.com/alatyr-programming-language/compiler
cd compiler && nix develop -c bash -c 'seed/alatyr build package.al'
cd -                                                # back to this repository
ALATYR="$OLDPWD/compiler/target/debug/alatyr" ./run.sh          # all benchmarks
ALATYR=… ./run.sh 01_hello                                      # just one
```

With no compiler the script **refuses and exits 2** rather than skipping Alatyr. That is deliberate:
a comparison table missing the language it exists to measure still looks like a result.

Other toolchains are optional — a missing one shows `-` in its column and is skipped. The Alatyr
compiler is the one exception, for the reason above.

## Layout

One directory per benchmark; inside it, one file per language, all named after
the benchmark:

```
benchmarks/
  run.sh                 # the single runner (build + measure + table)
  primes/
    primes.al            # Alatyr      (built: alatyr build, default profile)
    primes.c             # C           (built: cc -O2)
    primes.rs            # Rust        (built: rustc -O)
    primes.zig           # Zig         (built: zig build-exe -O ReleaseFast)
    primes.go            # Go          (built: go build)
    primes.ts            # TypeScript  (run: node — type-stripped, Node ≥ 22)
    primes.js            # JavaScript  (run: node)
    primes.php           # PHP         (run: php)
    primes.rb            # Ruby        (run: ruby)
    primes.py            # Python      (run: python3)
```

To add a benchmark `foo`, create `foo/foo.{al,c,rs,zig,go,ts,js,php,rb,py}`
(same algorithm, each idiomatic) — the runner discovers it automatically. Any
language whose file (or toolchain) is missing simply shows `-`.

The suite is built around **three complementary resource profiles**, so the
columns tell you *where* a language spends — not just one aggregate number:

| benchmark  | stresses        | what it isolates                                  |
|------------|-----------------|---------------------------------------------------|
| `hello`    | process startup | runtime/interpreter launch cost + I/O (no compute) |
| `primes`   | CPU             | code-generation quality (tight integer loop)      |
| `arraysum` | memory          | per-element footprint + allocator (a live array)  |

## The dev-shell re-exec

With the compiler resolved (see *Running them* above), the script can be started from
anywhere — it **re-execs itself under the project's `direnv` shell** if
the toolchain (`cc` / `rustc` / `zig` / `go` and the Alatyr `as`/`ld`) is not
already on PATH, so the compiled languages are not skipped:

```sh
./run.sh                 # every benchmark
./run.sh primes          # just one
REPEAT=10 ./run.sh       # best of 10 (default 5)
NO_COLOR=1 ./run.sh      # no colour
```

Progress (which benchmark/language is building/running, with an ellipsis) is
printed to **stderr** — a self-overwriting line on a terminal — so stdout stays
the clean table. If `direnv` is unavailable, run from inside the dev shell.

Output is one **boxed table per benchmark** (box-drawing), **columns =
languages** (Python last; the compiled C/Rust/Zig/Go grouped after Alatyr, the
scripted TS/JS/PHP/Ruby after them), with each metric on its own row:

```
┌───────────┬───────┬────────┬───────┬───────┬─────┬───────┬───────┬───────┬───────┬───────┬───────┐
│ benchmark │       │ Alatyr │ C     │ Rust  │ Zig │ Go    │ TS    │ JS    │ PHP   │ Ruby  │ Py    │
├───────────┼───────┼────────┼───────┼───────┼─────┼───────┼───────┼───────┼───────┼───────┼───────┤
│ primes    │ Time  │ 0.12s  │ 0.11s │ 0.10s │ -   │ 0.11s │ 0.16s │ 0.13s │ 0.68s │ 2.32s │ 4.39s │
│           │ Build │ 0.09s  │ 0.14s │ 0.16s │ -   │ 3.10s │ -     │ -     │ -     │ -     │ -     │
│           │ Mem   │ 520K   │ 1.8M  │ 2.2M  │ -   │ 2.3M  │ 69.9M │ 54.2M │ 35.7M │ 14.1M │ 11.6M │
│           │ Bin   │ 9K     │ 15K   │ 4.1M  │ -   │ 2.3M  │ -     │ -     │ -     │ -     │ -     │
│           │ Src   │ 379B   │ 499B  │ 444B  │ -   │ 360B  │ 351B  │ 334B  │ 363B  │ 244B  │ 342B  │
└───────────┴───────┴────────┴───────┴───────┴─────┴───────┴───────┴───────┴───────┴───────┴───────┘
```

First column is the **benchmark**; the second holds the **metric** label (so it
is not repeated in every cell); then one column per language.

- **Time** — best run wall-clock of `REPEAT` runs (for interpreted languages
  this folds in interpreter startup),
- **Build** — compile + link time, measured once (compiled languages; `-` for
  the interpreted TS / JS / PHP / Ruby / Python),
- **Mem** — peak resident set (max RSS; needs GNU `time`, else `-`),
- **Bin** — compiled binary size (`-` for interpreted languages),
- **Src** — source file size.

In each metric row the **best (smallest) value is shown in green and the worst
(largest) in red** on a terminal (disabled by `NO_COLOR` or when piped). A
language whose output differs from the reference (the first language's) is listed
under *mismatches*; a missing toolchain or source shows `-` and is skipped, not
an error.

## The benchmarks

### `hello` — startup / I/O

Write a single `Hello, world!` line and exit. There is essentially no compute,
so **Time** is dominated by process startup: a few milliseconds for the scripted
languages' interpreter launch, effectively zero for the compiled ones — and
**Mem** shows each runtime's baseline footprint with nothing allocated. The
freestanding Alatyr binary has no runtime to start: it goes straight to `_start`,
so it posts the smallest binary and the lowest RSS.

### `primes` — CPU

Count the primes below 1,000,000 by **trial division** — a tight,
allocation-free integer loop (`n % j == 0`, `j*j <= n`). CPU-bound, so it
isolates code-generation quality; it allocates nothing, so peak RSS reflects
each runtime's static footprint. All variants print `primes = 78498`. The Alatyr
version also exercises `std::fmt::print("{}")` (the Phase-C formatted output).

### `arraysum` — memory

Allocate an array of 10,000,000 integers, fill it `0 .. N-1`, then sum it (the
answer is `49_999_995_000_000`). The live array dominates the peak resident set,
so **Mem** exposes each runtime's **per-element footprint** — a flat 64-bit
array (C / Rust / Zig / Go / Alatyr, ~80 MB) versus boxed integers or hashed
arrays (Python / PHP, several times that) — and its allocator, where `primes`
shows pure compute. The Alatyr version uses `std::vec` (an mmap-backed growable
region, the Stdlib alloc tier) to hold and sum the array.

## Notes

- Alatyr is compiled with its **default profile**; its optimizer is the §3.5
  floor (no aggressive optimization yet, by design — transparent codegen, I1/I2),
  yet it stays competitive on simple integer loops and — being **freestanding**
  (no libc/runtime) — shows the smallest binary and lowest RSS of the compiled
  set, and the fastest **Build**.
- Numbers are machine-dependent and for *relative* comparison in one run, not
  absolute claims. The limit balances the interpreted runtimes against the
  compiled languages' need for measurable work.
- The Alatyr source carries **no manifest** — the default target is the build
  host (TOOL-3) — so its `Src` is a fair comparison; for the same reason all
  sources are idiomatically formatted and **carry no comments** (a comment would
  distort `Src`).
