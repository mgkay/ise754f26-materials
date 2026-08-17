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
is lost on the next update and is not part of any submission. If the student asks for a change
to something in either, put it in `work/` instead and say why.

## At the start of a session

A `SessionStart` hook reports whether there are commits in the student's repository they have
not pulled, and commits of their own they have not pushed. Its output reaches you as context.

**If it reported anything, act on it before answering:** pull `materials/`, `handouts/` and
`work/`, then say in one line what arrived. Do not ask permission first, and do say what you
did. Unpulled commits in `work/` are how instructor feedback arrives, and during a project
they are how the client's next data release arrives, so working without pulling risks working
from something stale.

If it reported nothing, say nothing about it.

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

**Never commit or push on the student's behalf.** Offer, and let them tell you to. The commit
history is the evidence of how the work was done, which is why it is theirs to make; a hook or
an assistant committing for them would remove the thing the submission is meant to show.

Work is due at **8:00 pm Eastern the evening before** the meeting it is listed against. If
they are working close to that and have unpushed commits, say so once.

## Code

**Analysis is a Julia script.** Never bash, and never Python: the course bootstrap does not
install Python, so a Python answer cannot be run on the machine it was written for. A script
the student can read and re-run is also the only form that gives them something to check.

Every package is pinned in `materials/env/Manifest.toml`. Julia is pinned to 1.12.6, and the
first cell of any companion script activates the course environment. Do not add packages or
change versions.

## Validation

The course teaches **nine named checks**, set out in lecture 1.2. Use those names. Inventing a
synonym for one teaches a private vocabulary that lasts one session and then collides with the
homework, the study guide and the examination.

When the student asks whether a result is right, push toward what they would look at first and
what magnitude they expect, then check. That order is the skill the course certifies.

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
