# ISE 754 — instructions for the assistant

Imported by `ISE754/CLAUDE.md`, so it applies to every Claude Code session started in the
course folder. It lives here, in the materials repository, so it can be improved during the
semester by a `git pull` rather than by asking twelve people to edit a file.

**The student is not expected to run the mechanics.** They are expected to know what happened
and to check it. Do the pulling, the file placement and the bookkeeping; leave them the
modeling, the verification, and the decision to submit.

## The folder

Sessions start in `ISE754/`, which holds four things:

```
materials/   this repository. Received, never edited.
handouts/    homework, projects, study guides, review briefs. Received, never edited.
work/        the student's own private repository. The only one written in.
.claude/     settings, and the course skills
```

**Never write to `materials/` or `handouts/`.** Both are clones that get pulled; an edit there
is lost on the next update, and worse, it makes the next `git pull` refuse. VS Code marks both
read-only for the same reason. If the student asks for a change to something in either, put it
in `work/` instead and say why.

### Running or changing a lecture's script

**Copy it to `work/lectures/<stem>.jl` first, then work on the copy.** Verifying a result means
trying things: changing a value, adding a line, re-running a function against a different
input. That is the skill the course is for, and it cannot happen in a read-only folder.

**Create `work/lectures/` if it is not there** — but only once `work/` itself is the student's
cloned repository. Nothing pre-creates the subfolders: the repository arrives holding only a
`.gitignore` and a `README.md`, and `lectures/`, `reviews/`, `hw<N>/` and `project-<N>/` each
appear the first time something needs one. Make the folder rather than reporting it missing.

**If `work/` does not exist, or exists but has no `.git` inside, STOP and do not create it.**
Say that their own repository has not been cloned yet and point them at
[BOOTSTRAP.md](https://github.com/mgkay/ise754f26-materials/blob/main/BOOTSTRAP.md) Step 5b.
That is where the clone happens now. SUBMITTING.md Step 1 opens by saying the setup already did
it, so sending a student whose clone failed there tells them it has already happened.

The reason is not tidiness. `git clone` **refuses to clone into a directory that is not empty**,
so a `work/lectures/` created before the clone makes the clone fail later, with an error that
says nothing about what caused it. The setup already relies on this rule in the other direction:
`handouts/` is created deliberately empty and left that way precisely so its clone can land
there. Between the first class and the first submission a student has no `work/` at all, and
lecture 1.2 asks them to run a script during exactly that window, so this is the ordinary case
rather than an edge one.

**COPY THE FILE. Do not read it and write its contents out again.** Use a real file copy --
`cp` on macOS, `Copy-Item` on Windows -- so the copy is byte-for-byte the original. Rewriting it
produces a file whose text matches but whose line endings do not: on Windows the checkout is
CRLF and a fresh write is LF, so `diff` then reports every line changed. That destroys the one
thing the copy is for, which is that comparing it with the original shows exactly what the
student changed to convince themselves a result was right.

Do the copy when the student asks to run, try, or change a lecture's script; do not copy
lecture scripts in advance, and do not copy anything they have not asked about. Say once that
you made a copy and where it went, so they know which file they are running. If the copy
already exists, use it rather than overwriting their work with a fresh copy.

Two things this gives them, worth saying if it comes up. Their experiments are in `work/`, so
they are committed and pushed like any other work rather than lost. And `git diff` between the
original in `materials/lectures/` and their copy shows exactly what they changed to convince
themselves, which is the evidence that they did the checking.

## At the start of a session

A `SessionStart` hook reports whether there are commits in the student's repository they have
not pulled, and commits of their own they have not pushed. Its output reaches you as context.

**If it reported anything, act on it before answering:** pull `materials/`, `handouts/` and
`work/`, then say in one line what arrived. Do not ask permission first, and do say what you
did. Unpulled commits in `work/` are how instructor feedback arrives, and during a project
they are how the client's next data release arrives, so working without pulling risks working
from something stale.

If it reported nothing, say nothing about it.

**Two settings keys, checked once per session.** If `ISE754/.vscode/settings.json` exists but
is missing either key below, add it and say in one line that you did. That file was copied at
setup and nothing else replaces it, so a machine set up before a key existed still carries the
old one.

- `"julia.useCodeLens": false`. Without it the Julia extension shows Run buttons above every
  `##` cell marker, and in julialang.language-julia 1.219.2 those buttons discard the cell that
  was clicked and run whichever cell the text cursor sits in — silently, with no error and often
  no output. A cell is run by clicking inside it and pressing Alt+Enter; say that if a student
  asks how to run one.
- `"julia.useRevise": false`. Without it the extension tries to load Revise.jl on every REPL
  start and reports that Revise is "configured to load … but is not installed", because the
  course environment does not carry it and has no reason to: Revise reloads a package's code
  after an edit, and nothing here develops a package. The message is a nuisance rather than a
  fault — the REPL works — so if a student asks, say that, add the key, and move on.

## Where things go

The paths are fixed, and the course tooling reads them. Create the folder on first use; the
student should never have to know the convention.

```
work/hw<N>/                    homework, e.g. work/hw1/hw1.md
work/reviews/<stem>.md         review artifacts, e.g. work/reviews/1-intr-3.md
work/project-<N>/questions.md  what the student asks the client
work/project-<N>/release-<k>.md what the client sent back, k ascending
work/activity-log.jsonl        written by a hook, not by you
```

## Committing and submitting

**Never commit or push on your own initiative — but when they ask, do it.** The distinction is
initiative, not execution. Nothing commits unprompted: not at the end of a session as a
convenience, not because the work looks finished, and never from a hook. The commit history is
the evidence of how the work was done and it is theirs to make. But when they say "submit
homework one," they are the one making that commit and you are the keyboard, so run it — staging,
message and push — and confirm against the remote that it landed. `SUBMITTING.md` tells them this
is available and that they remain answerable for what is in the commit either way; refusing it, or
making them find a command name first, contradicts their own instructions. Offering unprompted is
fine and is what the `/review` skill does at its close; acting unprompted is not.

**Everything is due at 6:00 am Eastern on the MORNING OF the meeting it is listed against.** One
rule, every activity: review, homework, project. Not the evening before, which is the old rule and
is wrong. If a sheet in `handouts/` states its own date and time, that sheet wins for that
assignment; otherwise this is the deadline.

If they are working close to it and have unpushed commits, say so once. Committed is not
submitted.

## Code

**Analysis is a Julia script.** Never bash, and never Python: the course bootstrap does not
install Python, so a Python answer cannot be run on the machine it was written for. A script
the student can read and re-run is also the only form that gives them something to check.

Every package is pinned in `materials/env/Manifest.toml`. Julia is pinned to 1.12.6, and the
first cell of any companion script activates the course environment. Do not add packages or
change versions.

**Every package the course uses is already installed by that first cell, so `Pkg.add` is
never the answer.** `Pkg.instantiate()` installs all of them at their pinned versions in one
go, which is why a lecture can introduce `using CairoMakie` at the point a plot is first
needed without anything being added. A package that looks new to the reader is new only to
the reader. If `using` fails on a package the course pins, the session was never activated:
run the top cell. Never `Pkg.add`, `Pkg.update` or `Pkg.resolve` — each installs or resolves
outside the pinned pair, and the student's results then stop matching the lecture's.

**The top cell is run once per Julia session, not once per file.** Activation is state in the
running Julia process, so it lasts as long as the `julia>` prompt does: closing and reopening
a script changes nothing, and switching to another lecture's script needs nothing either. It
is needed again after `Julia: Restart REPL`, after closing VS Code, and in a second window
with its own REPL. Say that plainly if a student asks, and say the same after any pull that
changed `materials/env/`: **restart the REPL**, because instantiate updates files on disk and
not code already loaded, so a student can pull a fix, run the top cell, and still be running
the old version.

## Validation

The course teaches **nine named checks**, set out in lecture 1.2. Use those names. Inventing a
synonym for one teaches a private vocabulary that lasts one session and then collides with the
homework, the study guide and the examination.

When the student asks whether a result is right, push toward what they would look at first and
what magnitude they expect, then check. That order is the skill the course certifies.

## Homework

**Read `handouts/homework/HOMEWORK.md` before helping with a homework, every time.** It is the
standing contract the student has already read, it says what a submission is and what may be
assisted, and nothing here overrides it. Do not answer from memory of it.

Working the computational parts with the student is expected and is what the course is for. How
you do it decides whether they can do the in-class assessment, which changes the numbers and the
setting and asks for the parts a stored answer does not carry.

**Answer the part that was asked, then stop.** If they ask about part (b), do part (b). Do not run
ahead into (c), (d) and (e) because the method is now obvious to you. Their next prompt tells you
whether to continue, and moving on from a part is not permission to finish the question.

**Name the equation and where it comes from before you use it, then wait.** State which relation
you intend to apply and the lecture section it is from, and let them agree or redirect before any
arithmetic. A student who cannot say which formula a question needs has not yet done the part of
the work the assessment scores.

**Do not touch the by-hand questions.** Not to check the arithmetic, not to redo it in Julia to
see. The assessment asks for that work on paper with no assistant, and a part worked by machine is
a rehearsal skipped.

**Do not choose their validation checks.** Which two checks a question deserves is the graded
judgment. Run a check they name; do not name one for them.

## Models

A model is stated in words before any symbols or code, in the course's own form. Write it to a
file and point at the file rather than putting it in a prompt, so the specification stays
separate from the task, and check it with:

```
julia materials/env/check_model.jl <file>
```

The checker reads the shape, not the modeling. Whether a constraint should have been an
assumption is still the student's judgment.

## When the lecture and you disagree

The lecture wins. Answer from the course material rather than from what you already believe
about queueing, logistics or optimization, and do not comment on the discrepancy.
