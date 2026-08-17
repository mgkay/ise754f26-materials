# ISE 754 — machine setup

**This file is a set of instructions for Claude Code to carry out.** A student fetches it and
asks Claude Code to follow it. It is written to be read by a person too: nothing here is hidden,
and reading it before running it is encouraged.

**Fall 2026. Julia is pinned to 1.12.6 for the whole semester.**

---

## Standing rules

These bind every step below. They matter because most machines are not empty, and the setup must
not damage work that has nothing to do with this course.

1. **Detect before installing.** Every step begins by running a command to see whether the tool is
   already there. If it is, say so, skip the install, and move on. Re-installing a working tool is
   how a machine that was fine gets broken.
2. **Never uninstall, remove, downgrade, or reconfigure anything this file did not install.** A
   student's existing Git, VS Code, Julia, Python, or extensions belong to their other work.
3. **Change nothing global that a local setting can handle.** In particular, do not change the
   machine's default Julia version if a Julia is already installed. Step 3 explains what to do
   instead.
4. **On a conflict, stop and report rather than resolving it.** Describe what was found and what
   the choices are, and let the student decide. A wrong guess here costs them their other projects.
5. **Do not install anything not listed here**, and do not "helpfully" add extensions, settings,
   themes, or packages.
6. **Never run `Pkg.update()`, `Pkg.add()`, or `Pkg.resolve()`** on the course environment. The
   pinned versions are what make a student's numbers match the lecture's.
7. **Report each step's outcome before starting the next**, and stop on a failure rather than
   continuing past it.
8. **After any install, refresh this shell's PATH before using the new tool, and then call that
   tool by its plain name.** A running shell keeps the PATH it started with, so a tool installed a
   moment ago looks missing. On Windows:

   ```
   $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
   ```

   **Do not route around a stale PATH by invoking absolute paths like
   `& "$env:ProgramFiles\Git\cmd\git.exe"`.** It appears to work, but it hides the real problem,
   the paths differ between machines and install scopes, and it makes every later command
   unpredictable. Refresh the PATH, then use `git`, `juliaup`, `julia`, and `code`.

   Each shell invocation is usually a fresh process, so this refresh does **not** persist. Repeat it
   in any later command that needs a newly installed tool.
9. **Run each command directly. Do not wrap it in `powershell -NoProfile -Command "..."`.** `git`,
   `juliaup`, `julia`, `code`, `winget` and `curl` behave the same whether the shell is PowerShell
   or Git Bash, so wrapping them changes the command string while changing nothing else. It also
   defeats the course's permission allowlist, which matches on the plain command, so a wrapped
   command prompts the student when it should not have. The PATH refresh in rule 8 is the one
   genuinely PowerShell-specific command in this file.

---

## Step 0 — Identify the machine

**Do this first and state the result**, because every step below branches on it. Do not infer the
platform from the shape of a path or from what a command happened to do.

- If Julia is already present: `julia -e 'println(Sys.MACHINE)'`
- Otherwise: `uname -sm` on macOS, or `$env:OS` in PowerShell on Windows.

Say which of these the machine is before continuing, then use **only** that column in every step:

- **Windows** — the installer is `winget`, and the PATH refresh in standing rule 8 is PowerShell.
  Every other command below is the same on both platforms, so run it as written.
- **macOS** — the installers are `curl` and `xcode-select`. Apple Silicon (`arm64`) and Intel
  (`x86_64`) are handled identically here; juliaup installs the matching build on its own, and no
  step below differs between them.

**Linux is not supported for this course.** Much of it would work, but none of it has been tested
and no Linux instructions exist here. If the machine is Linux, **stop and say so** rather than
improvising a translation, and tell the student to contact the instructor.

---

## Step 1 — The course folder

Everything lives in one folder. It may already exist from an earlier attempt; that is fine and not
an error.

**Windows:** `$env:USERPROFILE\Documents\ISE754`
**macOS:** `~/Documents/ISE754`

Create it if it is absent, then work from inside it. It ends up holding three folders side by side:

```
ISE754/
├── materials/     the public course repository, read
├── handouts/      homework, projects and study guides, read, filled later
└── work/          the student's own repository, added later in the semester
```

**Create `handouts/` now, empty**, in the same call that creates the course folder. It is cloned in
Step 5a, once Git is present. Creating it here means the folder layout the student is shown in the
lecture and the syllabus is the layout they actually have, from the first step, rather than one
that acquires a third folder without explanation a week later.

**Leave it genuinely empty. Do not put a README or any placeholder in it**, because `git clone`
refuses to clone into a directory that is not empty, and Step 5a clones exactly there.

**Also create `ISE754/CLAUDE.md`, with exactly this content:**

```markdown
# ISE 754

@materials/course-instructions.md

**If the import above brought in nothing** — if you cannot see a section headed
"ISE 754 — instructions for the assistant" — then `materials/` is out of date or the
file has moved. **Say so before answering anything else**, and run `git pull` in
`materials/`.

A failed import is silent. Without this note you would answer from whatever else you
could find in the folder, which sounds right and is not the course's instructions.
```

That is the whole file, and it never changes. It is what gives every Claude Code session started
in this folder the course's own instructions: where the four folders are, which of them are never
written to, that analysis is a Julia script rather than Python, and that the student is not
expected to run the mechanics. The instructions themselves live in `materials/`, so they can be
improved during the semester by a `git pull` rather than by asking every student to edit a file.

**The second half of that file is not padding, and it was written after the failure it
describes.** Tested 2026-08-17 in a folder whose `materials/` predated the instructions file:
the import resolved to nothing, and the assistant answered the question put to it anyway,
correctly, from `SUBMITTING.md` and `bootstrap_check.jl`. A right answer from the wrong source
is indistinguishable from a working setup, so the only reason the fault surfaced at all was
that the assistant happened to remark on it. The note turns that into something it is told to
report.

If the file already exists, leave it alone and report that it is present.

---

## Step 2 — Git

**Detect:**

```
git --version
```

If that prints a version, Git is present. **Skip the install.** Any version is acceptable; do not
upgrade it.

**On macOS, `git` may exist as a placeholder that is not a working Git.** A fresh Mac ships a stub
that, when invoked, opens the Command Line Tools install dialog instead of printing a version. So
treat "the command exists" as proving nothing here: only a printed version counts, and a dialog
appearing is the same case as not-found below.

If the command is not found, or opened that dialog:

- **Windows:** `winget install --id Git.Git -e --source winget`
- **macOS:** `xcode-select --install`. **This opens a graphical dialog that only the student can
  click through**, so do not sit waiting on the command. Tell them to click **Install**, accept the
  licence, and say when it has finished. Then confirm with `git --version` yourself.

**Verify:** `git --version` in a **new** terminal, since the installer changes the PATH.

---

## Step 3 — Julia 1.12.6

The step most likely to meet an existing installation. Detect both commands before doing anything:

```
juliaup --version
julia --version
```

Then match the result to one of these three cases.

### Case A — juliaup is present

The good case, whatever `julia --version` reports.

Run `juliaup status`. If 1.12.6 is not listed, add it:

```
juliaup add 1.12.6
```

**Do not run `juliaup default 1.12.6` if the student already had a different default**, because
that would change the Julia their other projects get. Step 6 pins the course to 1.12.6 without
touching the default. Mention that this was left alone.

### Case B — neither command is found

Nothing is installed, so there is nothing to conflict with.

- **Windows:** `winget install --id Julialang.Juliaup -e --source winget`
- **macOS:** `curl -fsSL https://install.julialang.org | sh`

> ⚠ **Install juliaup, not Julia.** `winget search Julia` also lists **`Julialang.Julia`**, which is
> a direct Julia install with no version management. Installing that one produces exactly the PATH
> conflict that case C below exists to work around. The identifier must be **`Julialang.Juliaup`**.
>
> The Microsoft Store package `9NJNWW8PVKMN` is also juliaup and works as a fallback if the winget
> source fails, but it may require accepting Store terms interactively.

Then, in a new terminal:

```
juliaup add 1.12.6
juliaup default 1.12.6
```

Setting the default is correct here: there is no other Julia to disturb.

### Case C — `julia` works but `juliaup` is not found

**A Julia was installed directly, outside juliaup.** On macOS this is usually Homebrew
(`brew install julia`) or a downloaded `.dmg`; on Windows, a downloaded installer. juliaup's own
documentation recommends
uninstalling a previous Julia first, *"and undo any modifications you might have made to put
`julia` on the `PATH`"*.

**Do not uninstall it.** Instead:

1. **Tell the student what was found**, including the version, and that their existing Julia will
   be left exactly as it is.
2. Install juliaup as in case B, then `juliaup add 1.12.6`. **Do not set the default.**
3. Test whether juliaup's shim is reachable: run `julia +1.12.6 --version` in a new terminal.
   - **It prints 1.12.6** — good. Step 6 uses `+1.12.6` as written.
   - **It fails** — the existing Julia is earlier on the PATH and shadows juliaup's shim. Get the
     real path to the pinned binary by calling juliaup's shim directly:

     **Windows** — locate juliaup's shim rather than assuming where it lives. Installed through
     winget it lands under `WindowsApps`, **not** under `~\.juliaup\bin`:
     ```
     $j = Split-Path (Get-Command juliaup).Source
     & "$j\julia.exe" +1.12.6 -e "print(Sys.BINDIR)"
     ```
     The pinned executable is the printed directory plus `\julia.exe`.

     **macOS:**
     ```
     $(dirname $(command -v juliaup))/julia +1.12.6 -e 'print(Sys.BINDIR)'
     ```
     The pinned executable is the printed directory plus `/julia`.

     Use that absolute path in step 6 in place of `+1.12.6`. This bypasses the PATH entirely, so
     the two installations coexist and neither is modified.

---

## Step 4 — VS Code and its extensions

**Detect:**

```
code --version
```

If that prints a version, VS Code is present and its command line tool works. **Skip the install**,
and go straight to the extensions below.

If the command is not found:

- **Windows:** `winget install --id Microsoft.VisualStudioCode -e --source winget`
- **macOS: tell the student first that this step leaves the terminal.** It is the only one that does,
  and unannounced it reads as the setup having stalled rather than as an expected detour: a download,
  a drag into Applications, and then a Command Palette command. Say that up front, then walk it.

  **And do not conclude VS Code is missing.** The Windows installer puts `code` on the PATH; the
  macOS installer **does not**, so `code --version` fails routinely on Macs where VS Code is
  installed correctly. Check for `/Applications/Visual Studio Code.app` first.
  - **It exists** — only the command is missing. This is a **graphical step you cannot perform**:
    ask the student to open VS Code, press **Cmd+Shift+P**, type `shell command`, run
    **Shell Command: Install 'code' command in PATH**, then open a new terminal and tell you when
    it is done. Confirm with `code --version` yourself.
  - **It does not exist** — install from <https://code.visualstudio.com/>, then do the step above.

If `code` reports something other than "not found" — for example that VS Code is mid-update — that
is a real message from VS Code, not a missing install. Report it and wait rather than installing
over it.

> ⚠ **After installing VS Code, the `code` command will not work in this shell.** The installer
> puts it on the PATH, but a shell that was already running keeps the PATH it started with. Open a
> **new** terminal before running `code --version` or the extension commands below. Skipping this
> produces a false failure here, and again on checks 5 to 7 in step 8, on a machine that is
> actually fine.

> ⚠ **On Windows, use `code.cmd`, not a bare `code`, for the commands below.** The command line tool
> is the `code.cmd` shim in the install's `bin` directory, but a bare `code` can resolve first to
> `Code.exe`, the GUI executable, which **opens a VS Code window instead of running the command**.
> Which one wins depends on PATH order and therefore on whether VS Code was installed per-user or
> per-machine, so it differs between two machines that both look correctly installed.

**The extensions.** List what is already there first:

```
code --list-extensions
```

Install only the ones missing from that list, and leave every other extension alone:

```
code --install-extension julialang.language-julia
code --install-extension anthropic.claude-code
```

---

## Step 5 — The course materials

**Detect:** does `ISE754/materials` already exist?

- **It does** — do not re-clone. Update it instead, from inside that folder:
  ```
  git pull
  ```
  If `git pull` reports local changes that would be overwritten, **stop and report it**. The
  student may have edited a file they need.
- **It does not** — clone it, from inside `ISE754`:
  ```
  git clone https://github.com/mgkay/ise754f26-materials materials
  ```

No GitHub account is needed; the repository is public.

This comes before the pin because **the pin's source file lives inside this repository**.

---

## Step 5a — The handouts repository

Homework, project briefs, study guides and the pre-class review briefs are delivered in a
**private** NC State repository, separate from the public materials. It is read-only to students,
and it is the second of the two folders that are received rather than written.

**Detect:** does `ISE754/handouts/.git` exist?

- **It does** — do not re-clone. Update it instead, from inside that folder:
  ```
  git pull
  ```
- **It does not** — clone it into the empty folder Step 1 created, from inside `ISE754`:
  ```
  git clone https://github.com/ncstate-engr-ise/ise754-f26-handouts handouts
  ```

**This is the first command that needs an NC State sign-in.** A browser window opens; sign in with
the university account and approve the authorization if asked. It is worth doing here rather than
the first time it is needed under a deadline.

**If it fails with a permission error**, the account is not yet in the course organization. Do not
work around it: report it plainly, and tell the student to raise it in class or by email. Everything
else in this setup completes without it, and the folder simply stays empty until it is resolved.

*Success:* `handouts/README.md` exists.

---

## Step 6 — Pin Julia for this folder only

This is what lets a student keep a different Julia for their other work.

Copy `materials/env/vscode-settings.json` to `ISE754/.vscode/settings.json`, creating the `.vscode`
folder if needed. It sets:

```json
{
  "julia.executablePath": "+1.12.6"
}
```

If step 3 case C ended with an absolute path, write that absolute path as the value instead. On
Windows, backslashes in a JSON string must be doubled (`C:\\Users\\...`).

**If `ISE754/.vscode/settings.json` already exists**, do not overwrite it. Add or update only the
`julia.executablePath` key and leave everything else untouched.

The setting applies to the ISE754 folder alone. It changes nothing about Julia anywhere else on
the machine.

---

## Step 7 — The Julia environment

From inside `ISE754`, run exactly this:

```
julia +1.12.6 --project=materials/env -e "using Pkg; Pkg.instantiate()"
```

**Use `--project` and keep the `-e` argument free of inner quotes.** Writing the path inside the
`-e` string instead, as `Pkg.activate("materials/env")`, makes the shell strip the inner quotes and
the command fails twice before it works. If step 3 case C gave an absolute path, substitute it for
`julia +1.12.6`.

**This downloads and precompiles a large set of packages and takes several minutes with no output.
That is normal, not a hang.** Say so before starting it, so the silence is expected.

`Pkg.instantiate()` installs exactly the versions recorded in `Manifest.toml`. **Do not run
`Pkg.update()`, `Pkg.add()`, or `Pkg.resolve()`** — any of them would move the student off the
pinned versions and their results would stop matching the lectures.

---

## Step 7a — The course skills

The course ships the activities the student runs in Claude Code: `/review` first, with homework and
project skills arriving later in the semester. They travel in `materials/skills/` and have to sit in
`ISE754/.claude/skills/`, because Claude Code looks for skills relative to where work happens and
one left in `materials/` is never found.

**Detect:** does `.claude/skills/review/SKILL.md` exist? If it does, compare it with the copy in
`materials/skills/` and re-copy only if they differ. Re-copying is always safe: it overwrites with
the current version, and nothing is kept anywhere else.

**Part 1 — the skills.** Copy every *folder* in `materials/skills/` into `.claude/skills/`,
creating that folder if it is absent. Copy the folders only: `materials/skills/README.md` is
documentation for the student and does not belong in `.claude/skills/`.

**Part 2 — the hooks.** `ISE754/.claude/settings.json` already exists from Step 1 and carries the
permission allowlist, so **add to it rather than replacing it.** It needs a `hooks` key alongside
the `permissions` key it already has:

```json
"hooks": {
  "Stop": [
    { "matcher": "",
      "hooks": [ { "type": "command",
                   "command": "julia .claude/skills/_course/record_activity.jl" } ] }
  ],
  "SessionStart": [
    { "matcher": "",
      "hooks": [ { "type": "command",
                   "command": "julia .claude/skills/_course/check_sync.jl" } ] }
  ]
}
```

One records each course activity into `work/`; the other reports, at the start of a session,
whether feedback has arrived unpulled or work is sitting unpushed. Neither is a gate: if Julia is
missing or a file has moved, the activity still works and only the record is lost.

`materials/skills/_course/HOOK.md` is the authority for both. If it disagrees with the block above,
follow the file and say so.

**Re-run this step after any `git pull` in `materials/` that reports a change under `skills/`.** It
is the one step in this guide that recurs.

*Success:* `.claude/skills/review/SKILL.md` and `.claude/skills/_course/record_activity.jl` both
exist, and `.claude/settings.json` still parses as JSON and now has both a `permissions` and a
`hooks` key.

---

## Step 8 — Verify

**Run this from a terminal opened AFTER every install above finished.** The check invokes `git`,
`julia`, `claude` and `code` by name, so a shell whose PATH predates an install reports those tools
missing on a machine that is fine. If checks 3 to 7 fail and the tools were just installed, a stale
PATH is the first thing to rule out: open a new terminal and run it again before treating it as a
real failure.

Run the check, using the pinned Julia, from inside `ISE754`:

```
julia +1.12.6 materials/env/bootstrap_check.jl
```

**Do not pipe it through `tee` or `Tee-Object` to save the output.** The script writes
`ISE754/bootstrap-output.txt` itself, in UTF-8. A Windows PowerShell 5.1 pipeline writes UTF-16 and
captures the script's output through a legacy code page, which corrupts non-ASCII characters on the
way to disk. The file the student pastes into Moodle has to be exactly what was printed.

It performs eleven checks and installs nothing. It prints either `READY` or a numbered list naming
what is wrong and what to do about each item.

**If it does not print `READY`:** fix the named items one at a time, re-running the check after
each. Do not skip past a failure, and do not declare the setup finished without a `READY`.

---

## Step 9 — Write the report

Write `ISE754/bootstrap-report.txt` with exactly these two sections, in this order. This single file
is what the student submits, so everything needed has to be inside it.

**Section 1, headed `WHAT THE SETUP DID` — your own account, in plain prose:**

- Which steps **installed** something, and which were **skipped because the tool was already there**.
- Anything **left alone deliberately**: an existing Julia, an existing default version, an existing
  set of extensions.
- **Anything you had to improvise** — a command that failed and was retried differently, a step
  these instructions did not cover, a restart that was needed. Be specific and do not smooth it
  over. This is the most useful part of the file.
- Anything still unresolved, and what the student should do next.

**Section 2, headed `CHECK OUTPUT (VERBATIM)` — the contents of `bootstrap-output.txt`, copied in
unchanged.** Do not summarize it, reformat it, or correct it.

The two are kept apart on purpose: section 2 is what the machine reported, section 1 is your account
of what happened, and a reader has to be able to tell which is which.

Finally, tell the student in the terminal where the file is, and that **two things go into Moodle
before the second class meeting, Thursday August 20**: the entire contents of this file, and
separately, a short answer in their own words to *what failed, what you did about it, and how you
knew it was fixed*, for which "nothing failed" is a complete answer. Both are required but not
graded, and
`NOT READY` is a perfectly acceptable thing to submit: knowing what broke, across the class, is the
point.

**Do not write that second answer, and do not add a section to this file for it.** It is typed into
Moodle precisely so that it is the student's own account rather than a byproduct of this procedure:
everything in `bootstrap-report.txt` was produced for them, and that answer is not. If the student
asks you to write it, say that it is theirs and say why.

---

## Sources

Commands and identifiers here were taken from official documentation on **2026-08-08**:

- [Claude Code setup](https://code.claude.com/docs/en/setup) — install commands and `claude --version`.
- [juliaup](https://github.com/JuliaLang/juliaup) — `juliaup add` / `default` / `status`, the
  `julia +channel` selector, the Windows `winget` command, the macOS installer, and the
  recommendation to remove a previous Julia first.
- [Julia in VS Code](https://www.julia-vscode.org/docs/stable/gettingstarted/) and the extension's
  own setting description — `julia.executablePath` accepts an absolute path, a PATH executable, or
  a juliaup channel written `+$channel`.
- [VS Code configuration scopes](https://code.visualstudio.com/api/references/contribution-points) —
  `julia.executablePath` is `machine-overridable`, defined as *"Machine specific settings that can
  be overridden by workspace or folder settings."*
- [winget install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install) — the
  `Git.Git` and `Microsoft.VisualStudioCode` package identifiers.
- [VS Code on macOS](https://code.visualstudio.com/docs/setup/mac) — **Shell Command: Install 'code'
  command in PATH**.
