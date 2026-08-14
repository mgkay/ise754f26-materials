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

## Before anything else: a supported machine

**This course supports macOS and Windows.** Specifically macOS 13 or later, or Windows 10 version
1809 or later, 64-bit.

**Linux is not supported**, even though every tool used here runs on it. These instructions are
written and tested for macOS and Windows only, so a Linux machine would mean translating untested
steps all semester. A Chromebook or an iPad will not work at all, because Julia and Visual Studio
Code need a desktop operating system.

If a supported machine is a problem, **say so before the course starts** rather than after. There is
no penalty and it is far easier to solve early.

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

If that prints a version number followed by `(Claude Code)`, you are done with this step — **go to
step 2.** The number itself does not matter and will not match any example here, since Claude Code
updates often.

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
mkdir $env:USERPROFILE\Documents\ISE754\.claude
cd $env:USERPROFILE\Documents\ISE754
Invoke-WebRequest -Uri https://raw.githubusercontent.com/mgkay/ise754f26-materials/main/env/claude-settings.json -OutFile .claude\settings.json
claude
```

**macOS:**

```bash
mkdir -p ~/Documents/ISE754/.claude
cd ~/Documents/ISE754
curl -fsSL https://raw.githubusercontent.com/mgkay/ise754f26-materials/main/env/claude-settings.json -o .claude/settings.json
claude
```

Everything for this course lives inside that `ISE754` folder.

**What that third line does, since you should not run a file you have not been told about.** Claude
Code asks permission before each command it runs. Left alone, the setup asks about thirty times,
and approving thirty commands you have not been given any basis to judge teaches the wrong habit.
That file is a short, readable **allowlist**: it pre-approves the commands this setup commonly
needs, so you are not asked about each one individually. Named packages, this one repository, the
pinned Julia. It is
[readable here](https://github.com/mgkay/ise754f26-materials/blob/main/env/claude-settings.json),
and it applies only inside the `ISE754` folder.

**Expect several prompts anyway.** The list does not cover everything, deliberately, and **anything
it does not cover stops and asks you.** When one appears, that is the design working. Read it rather
than reflexively approving, because that habit is the one this course is actually about.

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
Download https://raw.githubusercontent.com/mgkay/ise754f26-materials/main/BOOTSTRAP.md into this folder, then read that file and follow it exactly.
```

It says **download it, then read it** rather than "fetch it" for a reason. Fetching a web address
can hand back a *summary* of the page instead of the page, and a summarized instruction file is
worse than no file at all. Downloading it first guarantees Claude Code is working from the real
text, and leaves you a copy in your folder you can read yourself.

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

The check writes its own output to **`ISE754\bootstrap-output.txt`**. Claude Code then assembles
**`ISE754\bootstrap-report.txt`** from that file and its own account of the run, so the report has two
parts:

| Section | What it is |
|---|---|
| `WHAT THE SETUP DID` | Claude Code's account of the run: what it installed, what it skipped because you already had it, and anything it had to work around |
| `CHECK OUTPUT (VERBATIM)` | The check's own output, copied in unchanged |

Those are separate on purpose. The second is what your machine reported; the first is Claude Code's
description of what it did. Telling the two apart is the habit this whole course is built on.

**Two things go into Moodle before class on Thursday August 20:**

1. **The report.** Open `bootstrap-report.txt` and paste its entire contents, including a
   `NOT READY` one. An honest report of what broke is exactly what that meeting needs. Copying from
   the file is far easier than selecting text out of the terminal.
2. **A short answer, in your own words**, to: *what failed, what you did about it, and how you knew
   it was fixed.* Two or three sentences. **If nothing failed, write "Nothing failed."** That is a
   complete answer and counts for as much as a long one.

The second one is typed into Moodle rather than into the file on purpose. Everything in
`bootstrap-report.txt` was produced for you; that answer is yours. Reading an error, acting on it,
and confirming the result is the method this whole course runs on, and the first time it happens is
worth writing down.

To run the check again at any point, paste this into Claude Code:

```text
Run materials/env/bootstrap_check.jl with Julia, show me the full output, and update bootstrap-report.txt
```

---

## How Claude Code asks permission

Claude Code pauses and asks before it runs a command. How often it pauses depends on its
**permission mode**, and the mode changed for everyone in August 2026, so what you see may not match
what an older guide describes.

**From August 14, 2026, new sessions on Pro, Max, and Team plans start in auto mode.**<sup>[13]</sup>
In auto mode, a separate classifier model reviews each action before it runs and blocks anything
that "escalates beyond your request, targets unrecognized infrastructure, or appears driven by
hostile content Claude read."<sup>[13]</sup> Routine commands go through without asking. So the
setup may run start to finish with very few prompts, or none.

**You may see a one-time dialog** asking whether to switch to auto mode. That is this change
arriving, not something the course did.<sup>[14]</sup> Either answer is fine here.

**To see or change the mode:** the status bar shows it, as `⏸ manual mode on` or `⏵⏵ auto mode on`.
Press `Shift+Tab` to cycle.<sup>[13]</sup>

### Why the course does not rely on those prompts

It would be easy to assume the permission prompt is where you check the tool's work. It is not, and
Anthropic's own figures are the reason: users approve **97% of permission prompts**, and in a
controlled study human reviewers caught a dangerous command **13.6% of the time** while auto mode
blocked **89%** of the same commands.<sup>[14]</sup> A checkpoint you pass 97% of the time is not a
checkpoint.

So this course puts verification where it can actually be done:

- `bootstrap_check.jl` verifies the machine **mechanically**, by invoking each tool, rather than by
  asking whether it feels installed.
- Every computed result is checked against something independent, which is why the lectures print
  their numbers and why your script has to reproduce them.
- The in-class examinations are worked by hand, on paper.

Reading a prompt before approving is still a good habit, and worth keeping. It is simply not what
this course is testing. Note too that auto mode "reduces permission prompts but does not guarantee
safety,"<sup>[13]</sup> so on anything consequential outside this course, read before approving.

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

> ⚠ **One thing not to let it do, whatever the failure: change a package version.** If the failure is
> a package that will not load, the fix is `Pkg.instantiate()`, which installs exactly the versions
> `Manifest.toml` records. **Never `Pkg.update()`, `Pkg.add()`, or `Pkg.resolve()`** — each of those
> moves you off the pinned versions, and your results then stop matching the lectures. Say so if
> Claude Code proposes one: a fresh session fixing a package error has no way to know the versions
> are pinned unless told.

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

**A machine this cannot run on** is covered at the top of this page: macOS and Windows are the
supported platforms, and Linux, Chromebooks, and iPads are not.

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
└── work/          your own repository, added before the first submission
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
13. [Choose a permission mode](https://code.claude.com/docs/en/permission-modes) — the August 14,
    2026 default change, what the auto-mode classifier blocks, the `Shift+Tab` cycle and the status
    bar labels, and the caution that auto mode does not guarantee safety.
14. [Auto mode default in Claude Code](https://claude.com/blog/auto-mode-default-in-claude-code) —
    the 97% approval figure, the 13.6% versus 89% study result, and the one-time switch prompt.
