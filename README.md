# ISE 754 — Logistics Engineering, Fall 2026 materials

Everything you are **given** for the course: the Julia environment, companion scripts, homework,
projects, and study guides. Your own work lives in a separate, private repository; see the syllabus
under *Submitting Work*.

> ## Start here: **[SETUP.md](SETUP.md)**
>
> It walks through installing everything in order and ends with a script that checks the whole
> installation and prints `READY`. **You do not need to clone this repository yourself** — the setup
> does it for you, in the right place. No GitHub account is needed at any point.

The rest of this page is reference: what is here and where it goes.

## What is here

| Folder | Holds |
|---|---|
| `env/` | The Julia environment: `Project.toml`, `Manifest.toml`, and `bootstrap_check.jl`. Set up first; nothing else runs without it |
| `lectures/` | The companion script for each lecture, with any data it reads in a `data/` folder beside it |
| `homework/` | Homework statements and starter scripts, each with its own `data/` |
| `projects/` | Project briefs |
| `study-guides/` | Study guides for the examinations |

Data files are never stored on their own. Each sits beside the script or statement that uses it, so
"which data?" is answered by where you are standing.

Most folders are empty at the start of the semester and fill as the course goes. To pick up new
material later, ask Claude Code to update the materials, or run `git pull` from inside the
`materials` folder.

## Where this sits on your computer

Two folders side by side, neither inside the other:

```
ISE754/
├── materials/     this repository, you read it
└── work/          your own repository, you write it
```

Side by side rather than nested because **where you are standing when you run something decides
whether it works**. The setup puts `materials/` in the right place.

`work/` is the other half, and it arrives later: it is a private repository of your own, created for
you, that you clone beside this one and commit your coursework to. **[SUBMITTING.md](SUBMITTING.md)**
sets it up and describes the routine. Do that before **Tuesday August 25**, when the first
submission is due.

## The lectures themselves

The rendered lectures are on the course site, not in this repository:
**<https://mgkay.github.io/ise754f26/>**

That address is permanent. It names the Fall 2026 edition, so the lectures you were taught stay at
that URL and are not overwritten by a later offering.

## How this material was produced

These materials are written by **Michael G. Kay**. Claude Code was used throughout as a drafting and
checking tool, which is stated here rather than left implicit. Nothing reaches this repository
without being reviewed and approved by the instructor, who is the author of record on every commit.

That is the same standard this course asks of you: **the tool drafts, you verify, and you are
answerable for what you submit.** It is easier to ask that of you if the course does it visibly
itself.

## A note on the environment

`env/Project.toml` and `env/Manifest.toml` are the **exact** environment the lectures were run
against, so the numbers you get match the numbers the lecture prints. They are pinned to this
offering and are not updated in place. If you come back to this material years from now, this is the
environment that produced what you were taught.

**Do not upgrade Julia during the semester.** `bootstrap_check.jl` compares your running version
against the pin, so a drift is reported rather than silently changing your results.
