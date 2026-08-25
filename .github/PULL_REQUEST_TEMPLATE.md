## What this changes

<!-- A new benchmark, a fairer column, a new toolchain, or a harness fix. -->

## Kind

- [ ] New benchmark
- [ ] A column made fairer (unidiomatic code, wrong flags, or work the optimiser could delete)
- [ ] A toolchain added, so a column stops reading `-`
- [ ] Harness fix

## Numbers

<!--
Say what machine they ran on and how many times. A timing without its machine is not a measurement,
which is also why nothing here is ever a pass/fail check.
-->

```
paste the table
```

## Checklist

- [ ] `ALATYR=… ./run.sh <case>` produces a number or an honest `-` for every column
- [ ] The reference-output check does not flag `!`
- [ ] The result is **used** — printed, and derived from the whole computation, so the optimiser
      cannot delete the work and hand the win to the best dead-code eliminator
- [ ] No build step gained a `|| true`: a language must never fall out of the table quietly
- [ ] `bash -n run.sh` clean, if the harness changed
