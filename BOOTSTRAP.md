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

Throughout: Windows commands are PowerShell; macOS commands are the terminal. Use the ones matching
the machine you are on.

---

## Step 1 — The course folder

Everything lives in one folder. It may already exist from an earlier attempt; that is fine and not
an error.

**Windows:** `$env:USERPROFILE\Documents\ISE754`
**macOS:** `~/Documents/ISE754`

Create it if it is absent, then work from inside it. It ends up holding two folders side by side:

```
ISE754/
├── materials/     the course repository, read
└── work/          the student's own repository, added later in the semester
```

---

## Step 2 — Git

**Detect:**

```
git --version
```

If that prints a version, Git is present. **Skip the install.** Any version is acceptable; do not
upgrade it.

If the command is not found:

- **Windows:** `winget install --id Git.Git -e --source winget`
- **macOS:** `git --version` triggers the Command Line Tools prompt; accept it. Otherwise install
  Xcode Command Line Tools with `xcode-select --install`.

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
that would change the Julia their other projects get. Step 5 pins the course to 1.12.6 without
touching the default. Mention that this was left alone.

### Case B — neither command is found

Nothing is installed, so there is nothing to conflict with.

- **Windows:** `winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore`
- **macOS:** `curl -fsSL https://install.julialang.org | sh`

Then, in a new terminal:

```
juliaup add 1.12.6
juliaup default 1.12.6
```

Setting the default is correct here: there is no other Julia to disturb.

### Case C — `julia` works but `juliaup` is not found

**A Julia was installed directly, outside juliaup.** juliaup's own documentation recommends
uninstalling a previous Julia first, *"and undo any modifications you might have made to put
`julia` on the `PATH`"*.

**Do not uninstall it.** Instead:

1. **Tell the student what was found**, including the version, and that their existing Julia will
   be left exactly as it is.
2. Install juliaup as in case B, then `juliaup add 1.12.6`. **Do not set the default.**
3. Test whether juliaup's shim is reachable: run `julia +1.12.6 --version` in a new terminal.
   - **It prints 1.12.6** — good. Step 5 uses `+1.12.6` as written.
   - **It fails** — the existing Julia is earlier on the PATH and shadows juliaup's shim. Get the
     real path to the pinned binary by calling juliaup's shim directly:

     **Windows:**
     ```
     & "$env:USERPROFILE\.juliaup\bin\julia.exe" +1.12.6 -e "println(joinpath(Sys.BINDIR, \"julia.exe\"))"
     ```
     **macOS:**
     ```
     ~/.juliaup/bin/julia +1.12.6 -e 'println(joinpath(Sys.BINDIR, "julia"))'
     ```

     Use that absolute path in step 5 in place of `+1.12.6`. This bypasses the PATH entirely, so
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
- **macOS:** download from <https://code.visualstudio.com/>, then open VS Code, open the Command
  Palette with **Cmd+Shift+P**, type `shell command`, and run
  **Shell Command: Install 'code' command in PATH**. Open a new terminal and confirm `code --version`.

If `code` reports something other than "not found" — for example that VS Code is mid-update — that
is a real message from VS Code, not a missing install. Report it and wait rather than installing
over it.

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

## Step 5 — Pin Julia for this folder only

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

## Step 6 — The course materials

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

---

## Step 7 — The Julia environment

From inside `ISE754`, using the pinned Julia — `julia +1.12.6`, or the absolute path from step 3
case C:

```julia
using Pkg
Pkg.activate("materials/env")
Pkg.instantiate()
```

**This downloads and precompiles a large set of packages and takes several minutes with no output.
That is normal, not a hang.** Say so before starting it, so the silence is expected.

`Pkg.instantiate()` installs exactly the versions recorded in `Manifest.toml`. **Do not run
`Pkg.update()`, `Pkg.add()`, or `Pkg.resolve()`** — any of them would move the student off the
pinned versions and their results would stop matching the lectures.

---

## Step 8 — Verify

Run the check, using the pinned Julia, from inside `ISE754`:

```
julia +1.12.6 materials/env/bootstrap_check.jl
```

It performs eleven checks and installs nothing. It prints either `READY` or a numbered list naming
what is wrong and what to do about each item.

**If it does not print `READY`:** fix the named items one at a time, re-running the check after
each. Do not skip past a failure, and do not declare the setup finished without a `READY`.

---

## Step 9 — Report

Finish with a short summary for the student:

- Which steps **installed** something, and which were **skipped because the tool was already there**.
- Anything **left alone deliberately** — an existing Julia, an existing default, an existing
  extension set.
- The **full output** of the check.
- If anything is unresolved, what it is and what the student should do next.

Then tell them: **paste the entire check output into Moodle before the second class meeting,
Thursday August 20.** It is required but not graded. `NOT READY` is a perfectly acceptable thing to
submit — knowing what broke, across the class, is the point.

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
