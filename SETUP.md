# ISE 754 — Setting up your computer

**Fall 2026.** Three steps. Install Claude Code yourself, hand it one setup prompt, then run a script
that checks the result. Done in the first class meeting, with help in the room.

**Paste the check's output into Moodle before the second class meeting, Thursday August 20.** It is
required but not graded: it records that the machine works, and the list of what broke across the
class shapes what that meeting covers.

Every menu name, button label, command, and link below was taken from official documentation on
**2026-08-07** and is cited at the end. Anything that could not be verified says so.

---

## Step 0 — Before class

**A Claude subscription.** Claude Code requires a **Pro, Max, Team, or Enterprise**
subscription.<sup>[1]</sup> The free plan does not include it. Pro is about $20 per month, billed
monthly.

**Windows only: install Git.** Download it from <https://git-scm.com/downloads/win> and run the
installer, accepting the defaults.

> ⚠ Anthropic's documentation states that on Windows, "Git must be installed for local sessions to
> work."<sup>[1]</sup> Without it, step 1 fails when a folder is selected, with an error that does not
> name the cause. Macs include Git already.

**About 15 GB of free disk space.** Most of it is Julia's package cache, which is larger than it
sounds because it stores precompiled code and native graphics libraries.

---

## Step 1 — Install Claude Code and hand it the setup prompt

Download the installer from <https://claude.com/download> and run it. That page offers the right build
for the machine; on Windows take the ARM64 installer only if the processor is ARM.<sup>[1]</sup>

Launch Claude from the Applications folder on macOS or the Start menu on Windows, and sign in.

The app has three tabs, **Chat**, **Cowork**, and **Code**. Click the **Code** tab at the top
centre.<sup>[1]</sup> If it offers an upgrade instead, the subscription is not active yet.

Choose **Local**, click **Select folder**, and pick or create a folder named `ISE754` somewhere
convenient, such as under Documents.<sup>[1]</sup> Everything for this course lives inside it.

Now paste this in as a single message:

```text
Set up this machine for ISE 754. Work through these in order. After each one, tell me
whether it succeeded before you continue, and stop if one fails rather than skipping ahead.

1. Install Visual Studio Code.
2. Install juliaup, then run `juliaup add 1.12.6` and `juliaup default 1.12.6`.
   This course is pinned to Julia 1.12.6. Do not install or select any other version.
3. On macOS only: make the `code` command available on the PATH, then confirm that
   `code --version` works in a new shell.
4. Install the VS Code extension `julialang.language-julia`.
5. Install the VS Code extension `anthropic.claude-code`.
6. Clone https://github.com/mgkay/ise754f26-materials into a subfolder named `materials`
   inside the folder you are working in.
7. Instantiate the Julia environment in `materials/env` WITHOUT changing any package
   versions: activate that project and instantiate it, and do not run an update. This
   downloads and precompiles the packages and takes several minutes on a first run.
8. Create `hello.jl` in this folder, printing "Hello, World!", and run it with Julia.

Then stop and report which of the eight steps succeeded.
```

**Expect to approve a lot of commands.** Claude Code starts in **Manual** mode, which means it
proposes each command and waits.<sup>[1]</sup> That is roughly ten approvals for the prompt above. It
is not stuck, and reading what it proposes before approving is a habit this course is built around.

---

## Step 2 — Run the check

Everything so far can *appear* to have worked on a machine that is not actually ready. That is why
this step exists, and it is the only one that settles it.

Ask Claude Code:

> Run `materials/env/bootstrap_check.jl` with Julia and show me the full output.

The script tests eleven things and prints either `READY` or a numbered list of what needs attention.
It invokes each tool rather than looking for its files, says so when it cannot determine something
instead of guessing, and installs nothing.

**Paste the entire output into Moodle before class on Thursday August 20.**

---

## When it does not say READY

This is the normal case on at least some machines, and the loop is short:

1. **Read the named reason.** The script does not say "failed"; it says which of the eleven checks
   failed and why.
2. **Ask Claude Code to fix that one thing**, quoting the line. For example: *"bootstrap_check
   reports that the Julia VS Code extension is not installed. Install it and confirm."*
3. **Re-run the check.**

That loop, read the error, act on it, confirm the result, is the same discipline the whole course
applies to computational work. Doing it here first is deliberate.

**If it will not work at all, say so by the second class meeting rather than working around it
silently.** There is no penalty, and completion is recorded when the problem is resolved. A
locked-down work laptop, a blocked execution policy, or no administrator rights will stop this
process and none of it is your fault; the usual routes are a personal machine or a campus lab, and if
neither is possible we will sort out something individually. What does not work is staying quiet,
because every lecture from the third onward assumes a working toolchain.

A Chromebook or an iPad cannot run this: Julia and VS Code need a desktop operating system.

**Do not upgrade Julia during the semester**, even if something offers to. Julia 1.13 is expected
around October, in the middle of the term, and moving to it would change results that are meant to
match the lectures. The check compares the running version against the pin, so a drift is reported
rather than silently changing your numbers.

---

## Fallback: doing it by hand

If the single prompt stalls part-way and the recovery loop above is not getting anywhere, each step
can be done directly. Ask Claude Code for one at a time, or run the commands yourself.

**Visual Studio Code.** Install from <https://code.visualstudio.com/>.

**Julia, via juliaup.** On Windows,
`winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore`; on macOS,
`curl -fsSL https://install.julialang.org | sh`.<sup>[2]</sup> Then `juliaup add 1.12.6` and
`juliaup default 1.12.6`. Confirm with `julia --version`, which should print exactly
`julia version 1.12.6`.

**macOS: the `code` command.** Open Visual Studio Code, open the **Command Palette** with
**Cmd+Shift+P**, type `shell command`, and run **Shell Command: Install 'code' command in PATH**.
Restart the terminal, then confirm `code --version` works.<sup>[3]</sup>

**The two extensions.** `code --install-extension julialang.language-julia` and
`code --install-extension anthropic.claude-code`.<sup>[4]</sup>

**The materials.** `git clone https://github.com/mgkay/ise754f26-materials materials`, run from inside
`ISE754`. No GitHub account is needed. Two folders end up side by side, neither inside the other:

```
ISE754/
├── materials/     this repository, read only
└── work/          your own repository, added in the week of August 25
```

Side by side rather than nested because where you are standing when you run something decides whether
it works.

**The Julia environment.** Open `ISE754` in VS Code, open the Command Palette and run **Julia: Start
REPL**.<sup>[5]</sup> At the `julia>` prompt:

```julia
using Pkg
Pkg.activate("materials/env")
Pkg.instantiate()
```

The first run takes several minutes. **Do not run `Pkg.update()`** — it would move package versions
away from the ones the lectures were built against.

---

## Sources

Every UI label, command, and link above was taken from these pages on **2026-08-07**.

1. [Get started with the Claude Code desktop app](https://code.claude.com/docs/en/desktop-quickstart)
   — the three tabs and the **Code** tab, the subscription requirement, **Local** and **Select
   folder**, **Manual** permission mode, the separate ARM64 build for Windows, and the statement that
   Git must be installed on Windows for local sessions to work. The download page
   <https://claude.com/download> is used instead of the per-platform installer URLs that page lists,
   because those are direct API redirects a browser resolves but a link checker cannot.
2. [juliaup](https://github.com/JuliaLang/juliaup) — the `winget` and `curl` install commands and
   `juliaup add` / `juliaup default`.
3. [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac) — **Cmd+Shift+P**,
   `shell command`, and **Shell Command: Install 'code' command in PATH**.
4. [Julia in Visual Studio Code](https://code.visualstudio.com/docs/languages/julia) — the extension
   identifier `julialang.language-julia` and its publisher.
5. [Running code — Julia VS Code documentation](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
   — the **Julia: Start REPL** command.

---

## Notes for review — delete before this reaches students

**Three things need confirming on Windows, and they are the point of the Windows pass.** The guide
currently states each conservatively; if the pass contradicts one, this file changes.

1. **Does the desktop app really require Git on Windows before a local folder can be selected?** The
   two Anthropic pages disagree. The desktop-app page says Git "must be installed for local sessions
   to work"; the [CLI setup page](https://code.claude.com/docs/en/setup) says Git for Windows is
   "recommended… optional" and that Claude Code falls back to PowerShell without it. **This decides
   whether the student's manual work in step 0 is one item or two**, and whether Claude Code could
   install Git itself.
2. **Does `winget … -s msstore` prompt for Microsoft Store terms?** If it needs an interactive
   agreement on first use, step 2 of the setup prompt cannot complete unattended and the fallback
   command becomes the primary route on Windows.
3. **Does the one-prompt path actually complete?** Ten approvals in Manual mode, on a clean machine,
   with no step silently skipped.

**Two strings are not verified from documentation** and are used on weaker evidence:

- `anthropic.claude-code` — taken from the output of a working installation, not a documentation page.
- **Shift+Enter** for running the current line in the Julia REPL, used in earlier course material, is
  deliberately **not** stated here: the Julia VS Code docs describe `Julia: Execute Code in REPL`
  without giving a binding. Worth confirming from a real terminal and adding back if correct.

**One design note.** Collapsing the installs into a single prompt looks like it reintroduces the
defect the six-step redesign fixed, four installs behind one success criterion. It does not, because
that objection was to *eyeball* criteria: `bootstrap_check.jl` replaces them with eleven named
mechanical checks. The granularity belongs in the verification, not the installation. The six-step
sequence survives as the fallback section above, which is where it is genuinely useful.
