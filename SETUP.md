# ISE 754 — Setting up your computer

**Fall 2026.** This is the whole setup for the course. It is done in the first class meeting, with
help in the room, and it takes most of the period. Work through it in order.

The last step runs a script that checks the entire installation mechanically and prints `READY`, or
the specific reason it is not. **Paste that output into Moodle before the second class meeting,
Thursday August 20.** It is required but not graded: it records that the machine works, and the list
of what broke across the class shapes what that meeting covers.

Every menu name, button label, and command below was taken from the official documentation on
**2026-08-07** and is cited at the end. Where something could not be verified from documentation, it
says so.

---

## Before the first class

Two things to do in advance, because neither can be fixed quickly in the room.

**1. A Claude subscription.** Claude Code requires a **Pro, Max, Team, or Enterprise**
subscription.<sup>[1]</sup> The free Claude.ai plan does not include it. Pro is about $20 per month,
billed monthly.

**2. Windows only: install Git.** Download it from <https://git-scm.com/downloads/win> and run the
installer, accepting the defaults.

> ⚠ **Do not skip this.** Anthropic's documentation states that on Windows, "Git must be installed
> for local sessions to work."<sup>[1]</sup> Without it, step 1 below fails at the point where a
> folder is selected, and the reason is not obvious from the error. Macs include Git already.

**Roughly 15 GB of free disk space** is needed. Most of that is Julia's package cache, which is
larger than it sounds because it stores precompiled code and native graphics libraries.

---

## Step 1 — Install the Claude desktop app and open the Code tab

Download the installer from <https://claude.com/download> and run it. That page offers the right
build for the machine; on Windows, take the ARM64 installer only if the machine has an ARM
processor.<sup>[1]</sup>

Launch Claude from the Applications folder on macOS or the Start menu on Windows, and sign in.

The app has three tabs: **Chat**, **Cowork**, and **Code**. Click the **Code** tab at the top
centre.<sup>[1]</sup> If clicking it offers an upgrade instead, the subscription is not active yet.

Choose **Local**, then click **Select folder**, and pick or create a folder called `ISE754` somewhere
convenient, such as under Documents.<sup>[1]</sup>

**Success:** a question typed into the Code tab gets an answer.

By default the Code tab runs in **Manual** mode, so Claude proposes each change and waits for
approval before touching a file.<sup>[1]</sup> Leave it that way. Reading what it proposes before
accepting is a habit this course is built around.

---

## Step 2 — Have Claude Code install Visual Studio Code

In the Code tab, ask for it:

> Install Visual Studio Code on this machine, then tell me the version you installed.

**Success:** Claude Code reports a version number.

---

## Step 3 — Have Claude Code install Julia and the extensions, one at a time

Four separate things get installed here. **Ask for them one at a time and confirm each before moving
on.** Asking for all four at once is how a failure goes unnoticed: the summary can read as success
while one of them never installed.

**3a. Julia, via juliaup, pinned to the course version.**

> Install juliaup, then use it to install Julia 1.12.6 and make it the default. On Windows use
> `winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore`; on macOS use
> `curl -fsSL https://install.julialang.org | sh`. Then run `juliaup add 1.12.6` and
> `juliaup default 1.12.6`. Show me the output of `julia --version`.

**Success:** `julia --version` prints exactly `julia version 1.12.6`.<sup>[2]</sup>

> **The version matters.** `1.12.6` is the version the whole course is pinned to. **Do not upgrade
> Julia during the semester,** even if something offers to. Julia 1.13 is expected around October,
> in the middle of the term, and moving to it would change results that are supposed to match the
> lectures.

**3b. macOS only: put the `code` command on the PATH.**

This one is done by hand, because it is a menu action rather than a command.

Open Visual Studio Code. Open the **Command Palette** with **Cmd+Shift+P**, type `shell command`,
and run **Shell Command: Install 'code' command in PATH**. Then restart the terminal.<sup>[3]</sup>

**Success:** `code --version` prints a version in a *new* terminal window.

> ⚠ **macOS users, do not skip this.** The Windows installer adds `code` to the PATH; the macOS one
> does not. Until this is done, every step below that installs an extension from the terminal fails,
> and the failure surfaces much later as a missing command rather than as an install error.

**3c. The Julia extension for VS Code.**

> Install the VS Code extension `julialang.language-julia` and confirm it is listed as installed.

**Success:** the extension identifier `julialang.language-julia` appears in the installed
list.<sup>[4]</sup>

**3d. The Claude Code extension for VS Code.**

> Install the VS Code extension `anthropic.claude-code` and confirm it is listed as installed.

**Success:** `anthropic.claude-code` appears in the installed list.

---

## Step 4 — Get the course materials

Two folders sit side by side inside `ISE754`, neither inside the other:

```
ISE754/
├── materials/     this repository, read only
└── work/          your own repository, where you submit
```

Ask Claude Code to clone the materials:

> In my ISE754 folder, clone https://github.com/mgkay/ise754f26-materials into a subfolder named
> `materials`.

No GitHub account is needed for this. The `work/` repository comes later, in the week of August 25,
once accounts are set up.

**Success:** `ISE754/materials/env/Project.toml` exists.

> **Side by side, not nested.** Where you are standing when you run something decides whether it
> works. Nesting one inside the other breaks paths in ways that are hard to diagnose.

---

## Step 5 — Set up the Julia environment and run something

Open the `ISE754` folder in VS Code. Open the **Command Palette** and run **Julia: Start
REPL**.<sup>[5]</sup> A Julia banner appears above a green `julia>` prompt.

At that prompt, activate and install the course environment:

```julia
using Pkg
Pkg.activate("materials/env")
Pkg.instantiate()
```

**The first run downloads and precompiles everything and takes several minutes.** That is normal and
happens once.

Then ask Claude Code for a first program:

> Create a file `hello.jl` in my ISE754 folder that prints "Hello, World!", then run it.

**Success:** the line prints at the `julia>` prompt.

---

## Step 6 — Run the check

From the `julia>` prompt:

```julia
include("materials/env/bootstrap_check.jl")
```

It verifies the whole chain and prints either `READY` or a numbered list of what still needs
attention. It changes nothing and installs nothing.

**Paste the entire output into Moodle before class on Thursday August 20.**

Steps 1 to 5 can all appear to succeed on a machine that is not actually ready, which is the whole
reason this step exists. It is also the first instance of something this course returns to
constantly: verifying a result mechanically instead of trusting that it looks right.

---

## If it will not work

**Tell me by the second class meeting rather than working around it silently.** There is no penalty.
Completion is recorded when the problem is resolved.

A locked-down work laptop, a blocked execution policy, or no administrator rights will stop this
process, and none of those is your fault. The usual routes are a personal machine or a campus lab. If
neither is possible we will sort out something individually. What does not work is staying quiet:
every lecture from the third onward assumes a working toolchain.

A Chromebook or an iPad cannot run this, because Julia and VS Code need a desktop operating system.

---

## Sources

Every UI label, command, and download link above was taken from these pages on **2026-08-07**.

1. [Get started with the Claude Code desktop app](https://code.claude.com/docs/en/desktop-quickstart)
   — the three tabs and the **Code** tab, the subscription requirement, **Local** and **Select
   folder**, **Manual** permission mode, the separate ARM64 build for Windows, and the statement that
   Git must be installed on Windows for local sessions to work. The download page
   <https://claude.com/download> is used instead of the per-platform installer URLs that page lists,
   because those are direct API redirects that a browser resolves but a link checker cannot.
2. [juliaup](https://github.com/JuliaLang/juliaup) — the `winget` and `curl` install commands, and
   `juliaup add` / `juliaup default`.
3. [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac) — **Cmd+Shift+P**,
   `shell command`, and **Shell Command: Install 'code' command in PATH**.
4. [Julia in Visual Studio Code](https://code.visualstudio.com/docs/languages/julia) — the extension
   identifier `julialang.language-julia` and its publisher.
5. [Running code — Julia VS Code documentation](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
   — the **Julia: Start REPL** command.

**Not verified from documentation.** Two things in this guide were not confirmed against an official
page and should be checked against a real installation before this guide is relied on:

- The extension identifier `anthropic.claude-code` is taken from the output of a working install
  rather than from a documentation page.
- Earlier drafts of the course material used **Shift+Enter** to run the current line in the Julia
  REPL. The Julia VS Code documentation describes `Julia: Execute Code in REPL` without stating a
  keyboard shortcut, so that binding is deliberately not asserted here.
