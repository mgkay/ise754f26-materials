# The Fall 2026 Julia environment

**Julia version: `1.12.6`** — read from `Manifest.toml`. This is the pin for the whole
semester.

Install that version before anything else. `Manifest.toml` is only usable with a compatible
Julia, so a mismatch here is the first thing to check when nothing works.

```
juliaup add 1.12.6
```

**Do not upgrade Julia during the semester.** Julia 1.13 is expected around October, in the
middle of the term (1.11.0 and 1.12.0 both shipped on October 8, in 2024 and 2025). Staying
on the pinned version is what keeps your results matching the lectures, and
`bootstrap_check.jl` compares your running Julia against this pin, so a drift is reported
rather than silently changing your numbers.

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

✓ **Pin settled 2026-08-07: Julia 1.12.6.** It was resolved the correct way, by moving the
canonical environment and re-rendering every lecture against it, not by editing a printed
version number. So the lectures, this Manifest, and the setup instructions all name the same
version, and it is the one the toolchain was verified end to end on.

The re-resolve moved six packages, all of them standard-library or JLL components that ship
*with* Julia: `Downloads`, `Pkg`, `LibCURL_jll`, `MozillaCACerts_jll`, `OpenSSL_jll`,
`p7zip_jll`. **No computational package moved** — CairoMakie, DataFrames, GeoMakie, Optim,
Logjam and the rest are unchanged, which is why the lectures' numbers are unaffected.
`Pkg.update()` was deliberately *not* run; only Julia moved.
