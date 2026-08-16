# First use of a course activity

**Read this only when the student is running a course activity for the first time**, as
determined by the check in the skill's own first step. Every activity skill —
`/review`, and the homework and project skills as they arrive — uses this same file, so
what a student is told about the mechanics is said once and identically.

## How first use is decided

**By the student's own record, not by which item they are on.** The signal is
`work/activity-log.jsonl`: if no line in it carries this activity's name, this is the
student's first use of it.

That distinction is the whole reason this file exists. Keying the orientation to "the first
lecture" or "homework 1" gets it wrong in ways that will actually happen: a student who adds
the course late starts partway through and never sees it; a student who skips the first
homework meets the second one cold; and next semester, when the flag has moved on, nobody
sees it at all. The log is per-student and self-maintaining, so it is right in all three
cases without anyone remembering anything.

If the file does not exist, that is first use. If the hook has never run — no Julia, a
failed install — every session reads as first use, so the student gets the orientation
again rather than losing it, and `activity-log.error` says why.

## What to do differently

**Same activity, lighter load, mechanics made explicit.** Do not turn it into a tutorial
about Claude Code, and do not skip the substance: a first session that is all housekeeping
teaches the student that this activity is housekeeping.

1. **Say what the activity is and where it sits.** One or two sentences. The course runs
   lecture → review → homework → exam, each rung rehearsing what the next one assesses. Say
   which rung this is and what it is preparing them for.

2. **Say what is recorded, and what is not.** A record of the session is written to
   `work/activity-log.jsonl`. It carries no name — the repository it lands in already
   identifies them — and it does not contain the conversation. Say this once, plainly. A
   student who assumes a transcript is being uploaded behaves differently for the rest of
   the semester, and the assumption is wrong.

3. **Do less.** Cut the session's substantive work by about a third: where the brief marks
   three items, do the first and the last. Keep whatever the brief designates as the
   planted error or its equivalent — it is the memorable part, and cutting it would leave a
   first session that felt like a form to fill in.

   **Do not cut the activity's own artifact**, where it has one. Doing fewer items writes a
   shorter file; skipping the file entirely means the first session is the one that left no
   evidence, which is the opposite of the point.

4. **Close on committing and pushing, and be concrete.** This is the mechanical step that
   otherwise silently fails, and it is the one thing in this file that must not be skipped:

   > The record is written, but it is not submitted until it is pushed. From your `ISE754/work`
   > folder: `git add -A`, then `git commit -m "..."`, then `git push`.

   Say that work committed but not pushed has not been submitted, because it is still only
   on their machine. They will also see this as a system message when the session ends; say
   it anyway, because the first time is when it needs to land.

## What not to do

- **Do not ask them to confirm they understand.** They will say yes.
- **Do not walk through installing anything.** If the skill is running, it is installed.
- **Do not repeat this in later sessions.** The check exists so this happens once.
