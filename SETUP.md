# ISE 754 — Setting up your computer

**Fall 2026.** Four short steps. Claude Code does the installing; a script checks the result.
Done in the first class meeting, with help in the room.

The check prints either `READY` or the specific reason it is not. **Paste that output into Moodle
before the second class meeting, Thursday August 20.** It is required but not graded: it records
that the machine works, and the list of what broke across the class shapes what that meeting covers.

**Already have some of this installed?** That is expected and it is handled. Nothing here removes,
downgrades, or reconfigures software already on the machine — including an existing Julia, which is
left exactly as it is. Each step checks first and skips what is already working.

Every command, menu name, and link below was taken from official documentation on **2026-08-08** and
is cited at the end.

---

## Step 0 — Before class: two things

**1. A Claude subscription.** The documentation is explicit: *"Claude Code requires a Pro, Max,
Team, Enterprise, or Console account. The free Claude.ai plan does not include Claude Code
access."*<sup>[1]</sup> Sign up or upgrade at <https://claude.com/pricing>.

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
at that point rather than failing obscurely, so do step 1 early enough to fix it before class.

**2. About 15 GB of free disk space.** Most of it is Julia's package cache, which is larger than it
sounds because it stores precompiled code and native graphics libraries.

That is all to do in advance. **You do not need to install Git, Julia, or VS Code yourself.**

---

## Step 1 — Get the `claude` command

**Skip this step if you already have it.** Open a terminal and run:

```
claude --version
```

If that prints a version such as `2.1.224 (Claude Code)`, you are done with this step — **go to
step 2.**

> **Having the Claude desktop app is not the same thing.** The desktop app and the command line
> tool are separate installs.<sup>[1]</sup> They share one login, so if you have the app you are
> already signed in, but you still need the command below. Installing it does not affect the app,
> and the two work side by side.

To open a terminal: on **Windows**, press the Windows key, type `PowerShell`, and press Enter. On
**macOS**, press Cmd+Space, type `Terminal`, and press Enter. If you have never used a terminal,
this is the only point in the course where you meet a bare one.<sup>[2]</sup>

**Windows (PowerShell):**

```powershell
irm https://claude.ai/install.ps1 | iex
```

**macOS:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then confirm with `claude --version`.<sup>[1]</sup> If it still says command not found, open a
**new** terminal window first, since the installer changes the PATH.

---

## Step 2 — Start Claude Code in the course folder

Make the folder and start Claude Code inside it.

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

Everything for this course lives inside that `ISE754` folder.

**You can run this from any terminal** — a plain PowerShell or Terminal window, or the one built
into VS Code. It does not matter whether the Claude desktop app is installed, or whether VS Code is
already open with other projects. The `claude` command is independent of both.

On first run Claude Code opens a browser window so you can sign in.<sup>[3]</sup> **The browser is
used only for signing in. Claude Code itself runs in the terminal**, and you return there once the
sign-in finishes — the terminal shows `Login successful` and asks you to press Enter to
continue.<sup>[3]</sup> Nothing about this course runs in the browser.

If the browser does not open, press `c` to copy the login URL and paste it in yourself; if the
browser shows a code rather than returning you to the terminal, paste that code at the
`Paste code here if prompted` prompt.<sup>[3]</sup>

**Which model to use: whichever it starts on.** Claude Code opens on the model recommended for your
account type, and this course needs nothing else.<sup>[11]</sup> You can change it with `/model`,
but there is no reason to, and moving to a larger model uses up your plan's limits considerably
faster. If you do hit a usage limit, note that the limit is shared across models, so switching with
`/model` will not restore access; wait for the reset time the message gives you.<sup>[12]</sup>

---

## Step 3 — Give it one instruction

At the Claude Code prompt, paste this single line:

```text
Fetch https://raw.githubusercontent.com/mgkay/ise754f26-materials/main/BOOTSTRAP.md and follow it exactly.
```

That file is the actual setup procedure: it checks what is already installed, installs only what is
missing, and leaves everything else alone. **You can read it first** — open the link in a browser.
It is plain text, and reading what you are about to run is a habit this course is built around.

**Expect to approve a number of commands, and expect one long silence.** Claude Code starts in
**Manual** mode, proposing each command and waiting for you.<sup>[1]</sup> How many approvals
depends on how much is already installed. Setting up the Julia environment then sits with no output
for several minutes: **that is the normal case, not a hang.**

---

## Step 4 — Confirm it says READY

The last thing the setup does is run a check that tests eleven things and prints `READY`, or a
numbered list of what needs attention. It invokes each tool rather than looking for its files, says
so when it cannot determine something instead of guessing, and installs nothing, so it is safe to
run as often as you like.

It then writes **`ISE754\bootstrap-report.txt`**, which has two parts:

| Section | What it is |
|---|---|
| `WHAT THE SETUP DID` | Claude Code's account of the run: what it installed, what it skipped because you already had it, and anything it had to work around |
| `CHECK OUTPUT (VERBATIM)` | The check's own output, copied in unchanged |

Those are separate on purpose. The second is what your machine reported; the first is Claude Code's
description of what it did. Telling the two apart is the habit this whole course is built on.

**Open that file and paste its entire contents into Moodle before class on Thursday August 20**,
including a `NOT READY` one. An honest report of what broke is exactly what that meeting needs.
Copying from the file is far easier than selecting text out of the terminal.

To run the check again at any point, paste this into Claude Code:

```text
Run materials/env/bootstrap_check.jl with Julia, show me the full output, and update bootstrap-report.txt
```

---

## Working in VS Code

From here on, Claude Code runs inside the editor rather than in a bare terminal. Open the `ISE754`
folder in VS Code, open its integrated terminal with **Ctrl+`** (Cmd+` on macOS), and run `claude`
there. Same tool, same behaviour, now beside your files and the Julia REPL.

To start Julia itself, open the **Command Palette** and run **Julia: Start REPL**.<sup>[4]</sup>

---

## If you already had Julia installed

Nothing is removed and your default Julia is not changed. The course is pinned to Julia **1.12.6**,
and the setup pins it **for the `ISE754` folder only**, by writing `julia.executablePath` into that
folder's VS Code settings. The Julia VS Code extension accepts a juliaup channel as that value, and
the setting is `machine-overridable`, which VS Code defines as *"Machine specific settings that can
be overridden by workspace or folder settings."*<sup>[9]</sup>

So Julia in the ISE754 folder is 1.12.6, and Julia everywhere else on your machine is whatever it
was before. If you have a project that needs a different version, it keeps working.

One limit worth knowing: that setting governs the Julia the extension starts. If you type `julia`
into a bare terminal you still get your machine's default. The check reports the version it actually
gets, so a mismatch is named rather than silently changing your results.

**Do not upgrade Julia during the semester**, even if something offers to. Julia 1.13 is expected
around October, mid-term, and moving to it would change results that are meant to match the lectures.

---

## When it does not say READY

Expected on at least some machines. The loop is short:

1. **Read the named reason.** The script does not say "failed"; it says which of the eleven checks
   failed and why, and what to do about it.
2. **Ask Claude Code to fix that one thing**, quoting the line. For example:

   ```text
   bootstrap_check reports the Julia VS Code extension is not installed. Install it and confirm.
   ```

3. **Re-run the check.**

That loop — read the error, act on it, confirm the result — is the discipline the whole course
applies to computational work. Doing it here first is deliberate.

For installation problems specifically, `claude doctor` prints read-only diagnostics about the
install and settings without starting a session.<sup>[1]</sup> If `claude` behaves oddly and you
have installed it more than once over the years, the documentation has a **Check for conflicting
installations** section for exactly that.<sup>[1]</sup>

**If it will not work at all, say so by the second class meeting rather than working around it
silently.** There is no penalty, and completion is recorded when the problem is resolved. A
locked-down work laptop, a blocked execution policy, or no administrator rights will stop this and
none of it is your fault; the usual routes are a personal machine or a campus lab, and if neither is
possible we will sort something out individually. What does not work is staying quiet, because every
lecture from the third onward assumes a working toolchain.

A Chromebook or an iPad cannot run this: Julia and VS Code need a desktop operating system.

---

## Fallback: doing it by hand

If the setup stalls and the recovery loop is not getting anywhere, each piece can be done directly.
Check first in every case, and skip what is already present.

**Git.** `git --version`. If missing: `winget install --id Git.Git -e --source winget` on
Windows;<sup>[10]</sup> on macOS, `xcode-select --install`.

**Visual Studio Code.** `code --version`. If missing:
`winget install --id Microsoft.VisualStudioCode -e --source winget` on Windows,<sup>[10]</sup> or
<https://code.visualstudio.com/>.

**macOS: the `code` command.** Open VS Code, open the Command Palette with **Cmd+Shift+P**, type
`shell command`, and run **Shell Command: Install 'code' command in PATH**. Restart the terminal,
then confirm `code --version`.<sup>[6]</sup>

**Julia, via juliaup.** `juliaup --version`. If missing:
`winget install --id Julialang.Juliaup -e --source winget` on Windows, or
`curl -fsSL https://install.julialang.org | sh` on macOS.<sup>[5]</sup> **Install juliaup, not
Julia** — `Julialang.Julia` is a direct install with no version management and causes PATH
conflicts. Then `juliaup add 1.12.6`.
Add `juliaup default 1.12.6` **only if you had no Julia before**. Confirm with
`julia +1.12.6 --version`, which should print exactly `julia version 1.12.6`.

**The extensions.** `code --list-extensions` to see what you have, then install only what is
missing: `code --install-extension julialang.language-julia` and
`code --install-extension anthropic.claude-code`.<sup>[7]</sup>

**The folder pin.** Copy `materials/env/vscode-settings.json` to `ISE754/.vscode/settings.json`.

**The materials.** From inside `ISE754`:
`git clone https://github.com/mgkay/ise754f26-materials materials`. No GitHub account needed. If the
folder already exists, `git pull` inside it instead. Two folders end up side by side, neither inside
the other:

```
ISE754/
├── materials/     this repository, read only
└── work/          your own repository, added in the week of August 25
```

Side by side rather than nested because where you are standing when you run something decides
whether it works.

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

Taken from these pages on **2026-08-08**.

1. [Claude Code setup](https://code.claude.com/docs/en/setup) — the install commands for Windows
   PowerShell and macOS, the subscription requirement, that the desktop app is a separate download,
   `claude --version`, `claude doctor`, the conflicting-installations section, and **Manual**
   permission mode.
2. [Terminal guide](https://code.claude.com/docs/en/terminal-guide) — for anyone who has not used a
   terminal before.
3. [Authentication](https://code.claude.com/docs/en/authentication) — first-run browser login, the
   `c` shortcut to copy the login URL, and the paste-a-code fallback.
4. [Running code — Julia VS Code documentation](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
   — the **Julia: Start REPL** command.
5. [juliaup](https://github.com/JuliaLang/juliaup) — the `winget` and `curl` install commands,
   `juliaup add` / `default` / `status`, and the `julia +channel` selector.
6. [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac) — **Cmd+Shift+P**,
   `shell command`, and **Shell Command: Install 'code' command in PATH**.
7. [Julia in Visual Studio Code](https://code.visualstudio.com/docs/languages/julia) — the extension
   identifier `julialang.language-julia`.
8. [Claude pricing](https://claude.com/pricing) — Pro at $20 monthly or $17 per month billed
   annually at $200 up front, and that Pro and Max both include Claude Code.
9. [VS Code configuration scopes](https://code.visualstudio.com/api/references/contribution-points)
   — the definition of `machine-overridable`, the scope `julia.executablePath` declares.
10. [winget install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install) — the
    `Git.Git` and `Microsoft.VisualStudioCode` package identifiers.
11. [Model configuration](https://code.claude.com/docs/en/model-config) — the `/model` command, and
    that the default resolves to the recommended model for your account type.
12. [Manage costs](https://code.claude.com/docs/en/costs) — that usage windows are shared across
    models, so switching with `/model` does not restore access after a limit.

---

## Notes for review — delete before this reaches students

**Restructured 2026-08-08 to stop assuming a bare machine.** The previous version conflated
"install Claude Code" and "paste the setup prompt" into one step, so anyone who already had Claude
Code skipped to the next step and never saw the prompt. It also installed Git, VS Code and juliaup
unconditionally. Both are fixed: step 1 is skippable on a `claude --version` check, and the
procedure moved out of an inline pasted prompt into
[`BOOTSTRAP.md`](BOOTSTRAP.md), which detects before installing.

**Why a fetched file rather than a pasted prompt.** The paste is now one line that never changes,
the procedure can be arbitrarily detailed without making this page unreadable, and a case
discovered in week one is fixed by editing one file in the repository rather than by twelve
students re-copying anything. It matches the pattern already used for course instructions.

**The existing-Julia problem is solved by a folder-scoped pin, not by argument.** `.vscode/settings.json`
in the `ISE754` folder sets `julia.executablePath` to `+1.12.6`. Verified: the extension documents
that the setting accepts a juliaup channel in exactly that form, and VS Code documents
`machine-overridable` as workspace-overridable. Because the value is a channel name and not a path,
the same file is correct on every machine and is version-controlled at
`env/vscode-settings.json`. `BOOTSTRAP.md` step 3 case C carries the absolute-path fallback for a
directly-installed Julia that shadows juliaup's shim on the PATH — the case that actually occurred
on the instructor's ThinkPad.

**Verified on Windows 2026-08-07, on a stripped ThinkPad:** with Git uninstalled, `claude` started,
executed a command, and **used PowerShell as its shell tool**, exactly as the CLI documentation
describes. That is why Git is not a student prerequisite.

**`bootstrap_check.jl` was written 2026-08-08** and run against the instructor's desktop. It uses
only the Julia standard library, so it runs before the course environment is instantiated. Two real
defects surfaced on that first run and are fixed: it reported a mid-update VS Code as "the `code`
command was not found", which is the wrong diagnosis and would have sent a student to reinstall
something they already had; and it crashed on a `SubString`/`String` signature mismatch. It now
distinguishes *absent* from *present but failing* and passes the tool's own message through.

**Still open:**

1. ~~Does `winget … -s msstore` prompt for Microsoft Store terms?~~ **Resolved 2026-08-08.**
   `winget search Julia` on the ThinkPad returned **`Julialang.Juliaup` 1.21.0.0 from the `winget`
   source**, so the Microsoft Store is not needed and the terms prompt cannot arise. Both files now
   use `winget install --id Julialang.Juliaup -e --source winget`, with the Store package kept only
   as a fallback. The same search exposed **`Julialang.Julia`** on the winget source — a direct
   install with no version management, and the likely origin of the three competing Julia entries
   found on that machine. Both files now warn against it by name.
2. ~~Wall-clock time, cold, start to `READY`.~~ **Resolved 2026-08-08: 26 minutes**, cold, on a
   stripped Windows 11 ThinkPad. Comfortably under the 75-minute threshold. **But that is one
   machine on a home connection.** Twelve students pulling roughly 350 packages simultaneously over
   classroom wifi is a different measurement, and that contention is now the largest remaining
   schedule risk for class one. It degrades gracefully, since the submission is due before class 2
   rather than class 1, but the in-room plan should not budget 26 minutes per student.
3. ~~Does the fetched-BOOTSTRAP path complete end to end?~~ **Resolved 2026-08-08: yes, `READY`, all
   eleven checks.** It installed Git 2.55.0.windows.3, juliaup 1.21.0 **from the winget source**,
   Julia 1.12.6 set as default, VS Code 1.130.0, both extensions, the materials clone, and 351
   precompiled dependencies. All eleven passing also confirms the folder-scoped
   `.vscode/settings.json` pin was written correctly, which had only ever been tested by hand.
   **The approval count is still unrecorded.**
4. **macOS has not been exercised at all.** Every macOS command here is from documentation, not
   from a run, and no Mac is available. Two specific things to have a Mac student or the TA check:
   - **Does `Pkg.instantiate()` succeed on macOS against this Manifest?** `Manifest.toml` was
     resolved on Windows and contains a Windows-only JLL (`dlfcn_win32_jll`, pulled in by
     `SQLite_jll` via LightOSM). Julia manifests are designed to be cross-platform and this is
     expected to be harmless, but it has never been instantiated on a Mac. If it instead demands a
     re-resolve, the pin is at risk and the fix is a decision, not an edit.
   - **Does `bootstrap_check.jl` run clean on macOS?** Its only platform-specific code is the
     `cmd /c` wrapper it uses on Windows and the `code`-command advice it gives on macOS.
5. **The already-installed branches are still untested**, and they are the ones most students will
   actually take. The ThinkPad run was a bare machine, so step 3 case A and case C, the extension
   skip, and `git pull` in place of a clone have never executed. **Re-running the bootstrap on that
   same laptop now exercises all of them**, and with the depot warm it is a short test.

**Two strings not verified from documentation:**

- `anthropic.claude-code` — from the output of a working installation, not a documentation page.
- **Shift+Enter** for running the current line in the Julia REPL, used in earlier course material, is
  deliberately **not** stated: the Julia VS Code docs describe `Julia: Execute Code in REPL` without
  giving a binding. Confirm from a real terminal and add it back if correct.
