# ISE 754 — Setting up your computer

**Fall 2026.** Two things to do yourself. Everything else is installed for you, and a script checks
the result. Done in the first class meeting, with help in the room.

The check prints either `READY` or the specific reason it is not. **Paste that output into Moodle
before the second class meeting, Thursday August 20.** It is required but not graded: it records that
the machine works, and the list of what broke across the class shapes what that meeting covers.

Every command, menu name, and link below was taken from official documentation on **2026-08-07** and
is cited at the end. Anything not verified from documentation says so.

---

## Step 0 — Before class: two things

**1. A Claude subscription.** Claude Code requires a **Pro, Max, Team, or Enterprise** plan.<sup>[1]</sup>
The free plan does not include it. Sign up or upgrade at <https://claude.com/pricing>.

> ⚠ **Choose the monthly option, not the annual one.** Pro is **$20 billed monthly**, or $17 per
> month if you pay **$200 up front for the year**.<sup>[8]</sup> The annual plan saves $3 a month and
> commits you to twelve. Monthly means that if you drop the course, you stop paying.

**If you already have a Claude account, you probably do not need to buy anything new:**

| What you have | What to do |
|---|---|
| **Pro or Max** already | Nothing. Sign in with that account in step 1 |
| A **free** account | Upgrade the account you already have; keep the same login |
| **Team or Enterprise** through an employer | That works too, if the plan includes Claude Code. Sign in with it and check step 1 succeeds; if not, get a Pro plan |
| Nothing yet | Sign up for **Pro, monthly** |

You will not know for certain until you sign in. If the plan does not include Claude Code, it says so
at that point rather than failing obscurely — so do step 1 early enough to fix it before class.

**2. About 15 GB of free disk space.** Most of it is Julia's package cache, which is larger than it
sounds because it stores precompiled code and native graphics libraries.

That is all. **You do not need to install Git, Julia, or VS Code yourself** — Claude Code installs
them in step 1.

---

## Step 1 — Install Claude Code, then hand it one prompt

### Install it

Open a terminal. On **Windows**, press the Windows key, type `PowerShell`, and press Enter. On
**macOS**, press Cmd+Space, type `Terminal`, and press Enter. If you have never used a terminal, this
is the only point in the course where you meet a bare one, and it is two lines.<sup>[2]</sup>

**Windows (PowerShell):**

```powershell
irm https://claude.ai/install.ps1 | iex
```

**macOS:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Confirm it worked:<sup>[1]</sup>

```
claude --version
```

That prints a version such as `2.1.211 (Claude Code)`. If it says command not found, open a **new**
terminal window first, since the installer changes the PATH.

### Make the course folder and start Claude Code

**Windows:**

```powershell
mkdir $env:USERPROFILE\Documents\ISE754
cd $env:USERPROFILE\Documents\ISE754
claude
```

**macOS:**

```bash
mkdir -p ~/Documents/ISE754
cd ~/Documents/ISE754
claude
```

Everything for this course lives inside that `ISE754` folder. On first run Claude Code opens a
browser to sign in.<sup>[3]</sup> If the browser does not open, press `c` to copy the login URL and
paste it in yourself; if the browser shows a code rather than returning, paste that code at the
prompt.

### Paste this in as one message

```text
Set up this machine for ISE 754. Work through these in order. After each one, tell me
whether it succeeded before you continue, and stop if one fails rather than skipping ahead.

1. Install Git.
2. Install Visual Studio Code.
3. Install juliaup, then run `juliaup add 1.12.6` and `juliaup default 1.12.6`.
   This course is pinned to Julia 1.12.6. Do not install or select any other version.
4. On macOS only: make the `code` command available on the PATH, then confirm that
   `code --version` works in a new shell.
5. Install the VS Code extension `julialang.language-julia`.
6. Install the VS Code extension `anthropic.claude-code`.
7. Clone https://github.com/mgkay/ise754f26-materials into a subfolder named `materials`
   inside the folder you are working in.
8. Instantiate the Julia environment in `materials/env` WITHOUT changing any package
   versions: activate that project and instantiate it, and do not run an update. This
   downloads and precompiles the packages and takes several minutes on a first run.
9. Create `hello.jl` in this folder, printing "Hello, World!", and run it with Julia.

Then stop and report which of the nine steps succeeded.
```

**Expect to approve a lot of commands, and expect one long silence.** Claude Code starts in
**Manual** mode, proposing each command and waiting.<sup>[1]</sup> That is roughly a dozen approvals.
Step 8 then sits with no output for several minutes while it precompiles: **that is the normal case,
not a hang.** Reading what it proposes before approving is a habit this course is built around.

---

## Step 2 — Move into VS Code

From here on, Claude Code runs inside the editor rather than in a bare terminal.

Open the `ISE754` folder in VS Code. Open its integrated terminal with **Ctrl+`** (Cmd+` on macOS),
and run `claude` there. Same tool, same session behaviour, but now beside your files and the Julia
REPL.

To start Julia itself, open the **Command Palette** and run **Julia: Start REPL**.<sup>[4]</sup>

---

## Step 3 — Run the check

Everything so far can *appear* to have worked on a machine that is not ready. This is the step that
settles it. Ask Claude Code:

> Run `materials/env/bootstrap_check.jl` with Julia and show me the full output.

It tests eleven things and prints `READY`, or a numbered list of what needs attention. It invokes each
tool rather than looking for its files, says so when it cannot determine something instead of
guessing, and installs nothing.

**Paste the entire output into Moodle before class on Thursday August 20.**

---

## When it does not say READY

Expected on at least some machines. The loop is short:

1. **Read the named reason.** The script does not say "failed"; it says which of the eleven checks
   failed and why.
2. **Ask Claude Code to fix that one thing**, quoting the line — for example, *"bootstrap_check
   reports the Julia VS Code extension is not installed. Install it and confirm."*
3. **Re-run the check.**

That loop — read the error, act on it, confirm the result — is the discipline the whole course applies
to computational work. Doing it here first is deliberate.

For installation problems specifically, `claude doctor` prints read-only diagnostics about the
install and settings without starting a session.<sup>[1]</sup>

**If it will not work at all, say so by the second class meeting rather than working around it
silently.** There is no penalty, and completion is recorded when the problem is resolved. A
locked-down work laptop, a blocked execution policy, or no administrator rights will stop this and
none of it is your fault; the usual routes are a personal machine or a campus lab, and if neither is
possible we will sort something out individually. What does not work is staying quiet, because every
lecture from the third onward assumes a working toolchain.

A Chromebook or an iPad cannot run this: Julia and VS Code need a desktop operating system.

**Do not upgrade Julia during the semester**, even if something offers to. Julia 1.13 is expected
around October, mid-term, and moving to it would change results that are meant to match the lectures.
The check compares your running version against the pin, so a drift is reported rather than silently
changing your numbers.

**If you already had Julia installed**, say so when you run the setup prompt. A previous installation
can leave an older `julia` earlier on the PATH, so `juliaup default` does not win. The check catches
this, because it invokes `julia` and reports the version it actually gets rather than the version that
was requested.

---

## Fallback: doing it by hand

If the single prompt stalls and the recovery loop is not getting anywhere, each piece can be done
directly.

**Git.** <https://git-scm.com/downloads/win> on Windows; macOS includes it.

**Visual Studio Code.** <https://code.visualstudio.com/>

**Julia, via juliaup.** Windows: `winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore`.
macOS: `curl -fsSL https://install.julialang.org | sh`.<sup>[5]</sup> Then `juliaup add 1.12.6` and
`juliaup default 1.12.6`. Confirm with `julia --version`, which should print exactly
`julia version 1.12.6`.

**macOS: the `code` command.** Open VS Code, open the **Command Palette** with **Cmd+Shift+P**, type
`shell command`, and run **Shell Command: Install 'code' command in PATH**. Restart the terminal, then
confirm `code --version`.<sup>[6]</sup>

**The extensions.** `code --install-extension julialang.language-julia` and
`code --install-extension anthropic.claude-code`.<sup>[7]</sup>

**The materials.** From inside `ISE754`:
`git clone https://github.com/mgkay/ise754f26-materials materials`. No GitHub account needed. Two
folders end up side by side, neither inside the other:

```
ISE754/
├── materials/     this repository, read only
└── work/          your own repository, added in the week of August 25
```

Side by side rather than nested because where you are standing when you run something decides whether
it works.

**The Julia environment.** At the `julia>` prompt:

```julia
using Pkg
Pkg.activate("materials/env")
Pkg.instantiate()
```

First run takes several minutes. **Do not run `Pkg.update()`** — it would move package versions away
from the ones the lectures were built against.

---

## Sources

Taken from these pages on **2026-08-07**.

1. [Claude Code setup](https://code.claude.com/docs/en/setup) — the install commands for Windows
   PowerShell and macOS, the subscription requirement, `claude --version`, `claude doctor`, **Manual**
   permission mode, and that Claude Code uses PowerShell as its shell tool when Git for Windows is
   absent.
2. [Terminal guide](https://code.claude.com/docs/en/terminal-guide) — for anyone who has not used a
   terminal before.
3. [Authentication](https://code.claude.com/docs/en/authentication) — first-run browser login, the
   `c` shortcut to copy the login URL, and the paste-a-code fallback.
4. [Running code — Julia VS Code documentation](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
   — the **Julia: Start REPL** command.
5. [juliaup](https://github.com/JuliaLang/juliaup) — the `winget` and `curl` install commands and
   `juliaup add` / `juliaup default`.
6. [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac) — **Cmd+Shift+P**,
   `shell command`, and **Shell Command: Install 'code' command in PATH**.
7. [Julia in Visual Studio Code](https://code.visualstudio.com/docs/languages/julia) — the extension
   identifier `julialang.language-julia`.
8. [Claude pricing](https://claude.com/pricing) — Pro at $20 monthly or $17 per month billed
   annually at $200 up front, and that Pro and Max both include Claude Code.

---

## Notes for review — delete before this reaches students

**The route changed on 2026-08-07, deliberately.** Earlier drafts followed the TA's design, which
opened with the Claude **desktop app** and its Code tab. This version uses the **CLI, run in VS
Code's integrated terminal**, for four reasons: the instructor uses the CLI and can therefore support
it in a classroom, whereas he has never run the desktop app; the desktop app turned out to be
single-use scaffolding, since the TA's own step 4 already moved to "Claude Code in an editor-area
terminal"; students are in VS Code anyway for the Julia REPL; and Manual mode still shows diffs and
waits for approval in the terminal, so the review discipline survives. **The TA's substantive
contribution is untouched** — the granular-check insight and `bootstrap_check.jl` are what make
collapsing the install steps safe.

**Verified on Windows 2026-08-07, on a stripped ThinkPad:** with Git uninstalled, `claude` started,
executed a command, and **used PowerShell as its shell tool**, exactly as the CLI documentation
describes. That is why Git moved out of step 0 and into the setup prompt, and why the student's manual
work is now two items rather than three. The desktop app may genuinely require Git on Windows; that
remains untested and no longer matters.

**Still open:**

1. **Does `winget … -s msstore` prompt for Microsoft Store terms?** Microsoft's own documentation
   confirms Store agreement prompts are real winget behaviour. If it needs an interactive agreement,
   the fallback command becomes the primary Windows route. Also worth checking whether
   `winget search Julia` offers Julia from the `winget` source, which would avoid the Store entirely.
2. **Wall-clock time, cold, start to `READY`.** Nobody has this number and the first class period is
   spent on it. Above about 75 minutes it is a schedule problem.
3. **Does the one-prompt path complete**, and how many approvals.

**Two strings not verified from documentation:**

- `anthropic.claude-code` — from the output of a working installation, not a documentation page.
- **Shift+Enter** for running the current line in the Julia REPL, used in earlier course material, is
  deliberately **not** stated: the Julia VS Code docs describe `Julia: Execute Code in REPL` without
  giving a binding. Confirm from a real terminal and add it back if correct.
