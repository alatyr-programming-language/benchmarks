# Contributing to the Alatyr benchmarks

This repository compares one algorithm across ten languages. Contributions are welcome, and the bar
is not "make Alatyr look good" — it is **make the comparison honest**, including where Alatyr loses.

## What a good contribution looks like

- **A new benchmark**, with as many language columns as you can write. See `AGENTS.md` for the shape:
  one directory, one file per language, the same algorithm written idiomatically in each — not the
  same code transliterated, which measures translation rather than the language.
- **A fairer version of an existing one.** If a column is unidiomatic, slow for a reason that has
  nothing to do with the language, or accidentally measuring something else, say so and fix it. That
  is worth more than a new benchmark.
- **A missing toolchain** added to `flake.nix`, so a column stops reading `-`.

## The rules that keep it honest

- **The result must be used.** Print something derived from the whole computation. A benchmark whose
  output is discarded lets the optimiser delete the work, and then the winning column is just the
  best dead-code eliminator.
- **Never let a language disappear quietly.** A missing or failing optional toolchain shows `-`; a
  missing or failing Alatyr compiler/benchmark is a hard error. Do not add `|| true` to a build step — that is exactly how Alatyr once
  fell out of the table behind a one-line note on stderr.
- **Optimisation flags belong to the language, not to the benchmark.** Each column uses what that
  language's users would actually ship (`-O2`, `-O`, `ReleaseFast`, …). Hand-tuning one column and
  not the others is not a measurement.
- **Numbers need their machine.** If you quote a result in an issue or a PR, say what it ran on and
  how many times. Timings on shared or virtualised hardware are noise, which is also why nothing here
  is ever a pass/fail check.

## Before you open a PR

```sh
nix develop
ALATYR=/path/to/alatyr ./run.sh 0N_yourbenchmark
```

Every column you added should either produce a number or an honest `-`, the reference-output check
must not flag `!`, and `bash -n run.sh` should be clean if you touched the harness.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/) for new commits:
`<type>(<scope>): <imperative summary>`, for example `fix(runner): reject failed Alatyr runs`.
Keep the subject short and omit the trailing period. Suitable types here include `feat`, `fix`,
`docs`, `test`, `refactor`, `perf`, `ci`, and `chore`.

## Licensing of contributions

By contributing you agree that your contribution is licensed under **Apache-2.0**, the licence of
this repository.
