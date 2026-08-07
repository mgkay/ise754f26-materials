# ISE 754 — Logistics Engineering, Fall 2026 materials

Everything you are **given** for the course. Your own work lives in a separate, private
repository; see the syllabus under *Submitting Work*.

**Start here: [SETUP.md](SETUP.md)** walks through installing everything, in order, and ends with a
script that checks the whole installation and prints `READY`.

Clone this once and pull it as the semester goes. **No GitHub account is needed to clone it.**

```
git clone https://github.com/mgkay/ise754f26-materials.git materials
```

## What is here

| Folder | Holds |
|---|---|
| `env/` | The Julia environment: `Project.toml`, `Manifest.toml`, and `bootstrap_check.jl`. Set this up **first** — nothing else runs without it |
| `lectures/` | The companion script for each lecture, with any data it reads in a `data/` folder beside it |
| `homework/` | Homework statements and starter scripts, each with its own `data/` |
| `projects/` | Project briefs |
| `study-guides/` | Study guides for the examinations |

Data files are never stored on their own. Each one sits beside the script or statement that
uses it, so "which data?" is answered by where you are standing.

## Where this sits on your computer

Two clones side by side, neither inside the other:

```
ISE754/
├── materials/     this repository, you read it
└── work/          your own repository, you write it
```

Side by side rather than nested because **where you are standing when you run something
decides whether it works**.

## The lectures themselves

The rendered lectures are on the course site, not in this repository:
**<https://mgkay.github.io/ise754f26/>**

That address is permanent. It names the Fall 2026 edition, so the lectures you were taught
stay at that URL and are not overwritten by a later offering.

## A note on the environment

`env/Project.toml` and `env/Manifest.toml` are the **exact** environment the lectures were
run against, so the numbers you get match the numbers the lecture prints. They are pinned to
this offering and are not updated in place. If you return to this material years from now,
this is the environment that produced what you were taught.
