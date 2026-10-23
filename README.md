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

The other nine toolchains come from this repository's own `flake.nix`: `nix develop` (or `direnv
allow`, then just `./run.sh` — the harness re-execs itself under the shell when any comparison
toolchain or assembler/linker is absent).
Each comparison language is optional to the harness, so without that shell the columns simply read
`-`; the shell is what makes the table complete rather than what makes the script run. One column is
worth naming: peak RSS is read from GNU `time -f '%e %M'`, so without it every `Mem` cell is `-` —
the measurements that motivate a systems language are exactly the ones that vanish quietly.

With no compiler, or when Alatyr fails to build or run a benchmark, the script **refuses and exits
2** rather than skipping Alatyr. That is deliberate: a comparison table missing the language it
exists to measure still looks like a result.

Other toolchains are optional — a missing or failing one shows `-` in its column with a diagnostic.
The Alatyr compiler is the one exception, for the reason above.

## Layout

One directory per benchmark; inside it, one file per language, all named after
the benchmark:

```
benchmarks/
  run.sh                 # the single runner (build + measure + table)
  02_primes/
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

To add a benchmark `foo`, create `NN_foo/foo.{al,c,rs,zig,go,ts,js,php,rb,py}`
(same algorithm, each idiomatic) — the runner discovers it automatically. Any
language whose file (or toolchain) is missing simply shows `-`.

The suite is built around **complementary resource profiles**, so the
columns tell you *where* a language spends — not just one aggregate number:

| benchmark  | stresses          | what it isolates                                        |
|------------|-------------------|---------------------------------------------------------|
| `hello`    | process startup   | runtime/interpreter launch cost + I/O (no compute)      |
| `primes`   | CPU               | code-generation quality (tight integer loop)            |
| `arraysum` | memory            | per-element footprint + allocator (a live array)        |
| `bintrees` | allocation        | many small short-lived objects: allocator / GC / region |
| `interp`   | dispatch          | sum-type matching and recursion over a tree of nodes    |
| `blur`     | checked indexing  | bounds-checked loads/stores and integer arithmetic      |

## The dev-shell re-exec

With the compiler resolved (see *Running them* above), the script can be started from
anywhere — it **re-execs itself under the project's `direnv` shell** if
any comparison toolchain (`cc` / `rustc` / `zig` / `go` / `node` / `php` / `ruby` /
`python3`, plus `as`/`ld`) is not already on PATH, so the compiled languages are not skipped:

```sh
./run.sh                 # every benchmark
./run.sh 02_primes       # just one
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
under *mismatches*; a missing source or optional toolchain shows `-`, not an error.

## The benchmarks

### `hello` — startup / I/O

Write a single `Hello, world!` line and exit. There is essentially no compute,
so **Time** is dominated by process startup: a few milliseconds for the scripted
languages' interpreter launch, effectively zero for the compiled ones — and
**Mem** shows each runtime's baseline footprint with nothing allocated. The default Alatyr artifact
uses raw startup with no libc or managed runtime: it goes straight to
`_start`, so it posts the smallest binary and the lowest RSS.

### `primes` — CPU

Count the primes below 1,000,000 by **trial division** — a tight,
allocation-free integer loop (`n % j == 0`, `j*j <= n`). CPU-bound, so it
isolates code-generation quality; it allocates nothing, so peak RSS reflects
each runtime's static footprint. All variants print `primes = 78498`. The Alatyr
version also exercises the current reference compiler's `{}` formatting path through
`std::fmt::print`.

### `arraysum` — memory

Allocate an array of 10,000,000 integers, fill it `0 .. N-1`, then sum it (the
answer is `49_999_995_000_000`). The live array dominates the peak resident set,
so **Mem** exposes each runtime's **per-element footprint** — a flat 64-bit
array (C / Rust / Zig / Go / Alatyr, ~80 MB) versus boxed integers or hashed
arrays (Python / PHP, several times that) — and its allocator, where `primes`
shows pure compute. The Alatyr version uses `alloc::vec` over an arena from `std::os::arena`
(an mmap-backed growable region in the current reference compiler) to hold and sum the array.

### `bintrees` — allocation

The Benchmarks Game **binary-trees** algorithm at a fixed maximum depth of 17: build a stretch
tree of depth 18, keep one long-lived tree of depth 17 for the whole run, and for every even
depth from 4 to 17 build and walk `2^(17 - depth + 4)` complete trees. Each line prints the
total node count it walked; the output is identical everywhere. Each language allocates the way
it idiomatically would: C `malloc`/`free` per node, Rust a `Box` per node, Go / TypeScript /
JavaScript / PHP / Ruby / Python garbage-collected objects (tuples in Python), Zig an
`ArenaAllocator` reset after every tree. The Alatyr version uses the **region mechanism**: two
arenas from `std::os::arena` (one long-lived, one scratch), nodes placed with `@alloc(ar)`,
children held as `Option(Children)` of two `Handle(Node)`s and read back through `get`, and each
scratch tree freed in bulk by `close` — inside the timed process, like every other teardown.

### `interp` — dispatch

A tree-walking interpreter for a tiny expression language (`Const`, `Var`, `Add`, `Sub`, `Mul`,
`Lt`, `If`). A program of 4,614 nodes is generated deterministically from a seed (the
Park–Miller generator, depth ≤ 12), then evaluated 40,000 times with four input variables that
change every run; all arithmetic is masked to 20 bits so every language computes the same exact
integers. It prints the node count and the sum of the results. Dispatch is each language's
natural sum type: an Alatyr `enum` + `match`, a Rust `enum` + `match`, a C tagged union +
`switch`, a Zig tagged union + `switch`, a Go kind field + `switch`, a TypeScript discriminated
union, and objects, arrays or tuples in the dynamic languages. The other languages keep the nodes
in an array and refer to children by index; the Alatyr version places them in an arena and refers
to children by `Handle(Expr)`, which is that same index into the region.

### `blur` — checked indexing

A 3×3 box blur over a 1024×1024 grayscale image generated by the same Park–Miller sequence,
100 passes ping-ponging two buffers, edges clamped; it prints the sum of the final image. The
Alatyr version deliberately uses the language's **default checked arithmetic and bounds-checked
indexing** — no `unchecked` block — because this case exists to show what the checked default
costs. Its kernel indexes `Slice(u64)` views of two `alloc::vec` buffers. Pixels are `u32` in
every other language but `u64` in Alatyr: the current reference compiler miscompiles `Vec` and
slice elements narrower than a machine word, so the Alatyr buffers are twice as large, which
shows in its `Mem` cell.

Every benchmark has all ten languages; none is missing.

## Notes

- Alatyr is compiled with the manifest-less default `debug` profile; §3.5 is the
  specification's guaranteed minimum, while the implementation may optimize further.
  The artifact uses raw startup with no libc or managed runtime, yet stays competitive
  on simple integer loops and shows the smallest binary and lowest RSS of the compiled
  set, and the fastest **Build**.
- Numbers are machine-dependent and for *relative* comparison in one run, not
  absolute claims. The limit balances the interpreted runtimes against the
  compiled languages' need for measurable work.
- The Alatyr source carries **no manifest** — the default target is the build
  host (TOOL-3) — so its `Src` is a fair comparison; for the same reason all
  sources are idiomatically formatted and carry no explanatory comments.
- The Alatyr sources target the current reference compiler surface:
  `std::fmt`, `std::os::arena`, `alloc::vec`, and the region mechanism (`Arena`, `Handle(T)`,
  `@alloc`, `get`, `close`). The specification's v1 standard-library
  commitments are narrower, so this suite measures the shipped compiler API rather than
  asserting that every path is a stable language-spec guarantee.
