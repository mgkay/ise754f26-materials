---
name: submit
description: Submit course work to your GitHub repository. Stages, commits and pushes what you have written, checks the layout the course expects, and confirms with the remote that the push actually landed. Invoke as /submit hw1, /submit review 1.3, or by simply saying "submit homework one".
---

# /submit — put work on the record for ISE 754

The student has written something and wants it submitted. **You run the commands; they decide
that it happens.** That split is the whole posture of the course toward work with their name
on it, and it is not a formality: `SUBMITTING.md` says *"You are answerable for what is in
the commit either way — the tool does the work, and you check it before it goes out."*

**Invoked by intent, not only by syntax.** `/submit hw1` works, and so does "submit homework
one", "push my review", "hand this in". If a student says any of those, this is what they
mean. Do not make them find a command name.

**Never run this uninvited.** Not at the end of a session as a convenience, not because work
looks finished, not from a hook. The commit history is evidence of how the work was done and
it is theirs to make; an assistant committing unasked removes the thing the submission is
meant to show. Offering is fine — the `/review` skill offers at its close, which is where
most of the forgetting happens — but the student says yes.

## Step 0 — update the course, before anything else

Run this first, every time, before reading anything else:

```
julia .claude/skills/_course/update_course.jl --skill submit
```

It fast-forwards `materials/` and `handouts/` and reinstalls any skill that shipped a new
version. It never touches `work/`. Offline, it says nothing and changes nothing, and the
submission continues on what is on disk.
**Run it from the `ISE754` folder**, and if the session is somewhere else, change to that
folder first. The path above is relative, so from `work/` or `materials/` it resolves to
nothing and Julia exits with a stack trace instead of a report.

**This is not the same pull as Step 2, and neither replaces the other.** Step 0 updates the
*course* — `materials/`, `handouts/`, and the installed skills — and is documented as never
touching `work/`. Step 2 pulls `work/`, which is the student's own repository and the only
place their submission goes. A skill that ran only Step 2 would keep working forever on
whatever version of itself was installed the first time.

That was this skill's state until VERSION 2. `/review` and `/homework` both carried this step
from the day they shipped; `/submit` did not, and because it is reached from `/review`'s close
or straight after `/homework` — both of which have already updated — the gap was invisible.
It only bites on the path this skill deliberately invites: a student typing "submit homework
one" cold, with no other skill run first. On that path there was nothing that could ever
replace a stale copy.

## Step 1 — work out what is being submitted, and where it goes

The paths are fixed by the course and the student should never have to remember them:

| Work | Path |
|---|---|
| Homework *N* | `work/hw<N>/` — e.g. `work/hw1/hw1.md` and `work/hw1.jl` as `work/hw1/hw1.jl` |
| A review | `work/reviews/<stem>.md` — e.g. `work/reviews/1-intr-3.md` |
| Project *N* questions | `work/project-<N>/questions.md` |

**If `work/` does not exist, or exists without a `.git` inside, stop.** Their repository has
not been cloned yet. Say so and point at
[BOOTSTRAP.md](https://github.com/mgkay/ise754f26-materials/blob/main/BOOTSTRAP.md) Step 5b.
Do not create the folder: `git clone` refuses a non-empty directory, so a folder made now
makes the clone fail later with an error that says nothing about the cause.

## Step 2 — pull first

```bash
git -C work pull --no-rebase
```

**Before staging anything.** Feedback from the instructor or the TA arrives as commits on the
remote, and if any are unpulled the push at Step 5 is rejected — mid-submission, which is the
worst moment to meet it. Pulling first turns a confusing failure into a non-event.

`--no-rebase` is not optional. Without it git may be configured to rebase, which rewrites
their commits and can leave the push still rejected.

## Step 3 — say what is there, and what is missing

Look at what is actually in the folder and report it. For homework the course asks for two
files, the written answers and the script that produced them, and **a missing script is worth
saying out loud** — `SUBMITTING.md` is explicit that the script submitted is the one they
actually ran.

**Say what you find; do not decide whether the work is done.** Checking that `hw1/` holds
`hw1.md` and `hw1.jl` is not checking that the homework is finished, and you must not imply
otherwise. If something looks absent, name it and let them answer.

**If nothing has changed**, say so and stop. There is nothing to submit and a commit saying
so is noise in a history that gets read.

## Step 4 — commit with a message that says what changed

```bash
git -C work add -A
git -C work commit -m "HW 1: bracketing estimate and the I-40 median"
```

**Propose the message from what actually changed** and let them amend it. `SUBMITTING.md`:
*"Write messages that say what changed, not 'update'."* The history is part of what is looked
at, so `HW 1: added the simulation and its replication runs` is worth the ten seconds and
`update` is not.

**Commit as they go, not once at the end.** If they are submitting a whole homework in one
commit an hour before the deadline, that is their call and you do not lecture them about it —
but if they ask, five commits over two days shows more about the work than one does.

## Step 5 — push, then verify against the remote

```bash
git -C work push
git -C work status -sb
```

**A push that failed silently looks exactly like one that worked until you look.** So do not
report success from the absence of an error. Read the `status -sb` output and say plainly
whether the branch is level with `origin`, and name the commit that landed.

**Tell them the one thing that decides whether it counts:** work that is committed but not
pushed has not been submitted. Until the push, it is only on their machine.

### If the push is rejected

Say what failed and stop. Do not retry in a loop. It almost always means a commit exists on
the remote that they do not have — usually feedback — so `git -C work pull --no-rebase` and
push again, which is Step 2 arriving late.

**`git push --force` is never the answer.** It can delete work already submitted, including
feedback that was written into the repository. If they ask for it, say no and say why.

### If it fails days after a clone that worked

The message will sound like a permission problem and will not be one. `SUBMITTING.md` covers
it; send them there rather than guessing at credentials.

## Step 6 — the deadline, said once

Work is due at **6:00 am Eastern on the morning of the meeting it is assessed at**. That
is absolute, the same for both sections, and it is when submissions are collected to prepare
that morning's class. **Anything pushed later is not in that set.**

If they are submitting close to that time and something is still unpushed, say so once. Once
is the whole instruction — a second reminder is nagging and they are adults.

## What this skill is not

**It is not a grader and not a reviewer.** It does not judge whether the answers are right,
whether the checks were named, or whether the script runs. If asked, say that submission and
assessment are separate and offer to look at the work as a separate request.

**It does not write the work.** If the folder is empty, the answer is that there is nothing to
submit, not an offer to draft something.

**It does not touch `work/activity-log.jsonl`.** That file is written by a hook. Reading it is
fine; writing it is not.
