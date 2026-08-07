# The Fall 2026 Julia environment

**Julia version: `1.12.1`** — read from `Manifest.toml`.

Install that version before anything else. `Manifest.toml` is only usable with a compatible
Julia, so a mismatch here is the first thing to check when nothing works.

```
juliaup add 1.12.1
```

Then, from the `ISE754/materials/env` folder:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()      # first run downloads and precompiles; it takes a few minutes
```

Run `bootstrap_check.jl` afterwards. It verifies the whole toolchain mechanically and prints
`READY`, or a named reason it is not.

## Why these files are pinned and never updated in place

`Project.toml` lists the packages; `Manifest.toml` records the **exact** version of each one,
plus the Julia version. Together they are the environment the lectures were executed against,
so the numbers you compute match the numbers the lecture prints.

They belong to **this offering** and are frozen with it. A later offering gets its own
repository with its own pinned pair, rather than these being rolled forward — otherwise
returning to this material years later would silently give you a different environment from
the one you were taught in.

## For maintainers

**These two files are copied verbatim from the `ISE754-dev` project root, which is the single
canonical pair.** That root environment is what `quarto render` executes every lecture
against, so shipping anything else here would let a student's run disagree with the published
numbers. Do not hand-edit them here. Regenerate by copying from the canonical pair.

⚠ **Open as of 2026-08-07:** this Manifest pins **1.12.1**, while the toolchain was verified
end to end on **1.12.6**. The pin decision is still open, and it is not resolved by editing
this file — it is resolved by re-resolving the canonical environment at the chosen version
and copying the result here. Until then this ships what the lectures were actually rendered
with, which is 1.12.1.
