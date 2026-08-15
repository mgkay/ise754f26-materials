# skills

The course skills you run in Claude Code. **One workflow for all of them**: they arrive
here, and you install them the same way each time. Review is the first; homework and
project skills follow, and they will appear in this folder without the update procedure
changing.

## Installing them

The skills have to sit in `ISE754/.claude/skills/`, not in this folder. Claude Code looks
for skills relative to where you are working, and you work in `ISE754/work/`, so a skill
left here is never found.

The simplest way is to ask Claude Code to do it, from inside your `ISE754` folder:

> Copy every folder in `materials/skills/` into `.claude/skills/`, creating that folder if
> it does not exist, and add the review Stop hook to `.claude/settings.json` as described
> in `materials/skills/review/HOOK.md`.

Do it once now, and again after any `git pull` in `materials` that reports a change under
`skills/`. Reinstalling is safe: it overwrites with the current version and nothing is
kept anywhere else.

## What is here

| Folder | What it does | Run it |
|---|---|---|
| `review/` | Pre-class review of one lecture: rehearses that lecture's worked examples as verification practice and answers your questions against the lecture. Ungraded, records completion. | `/review 1.3` |

## Checking it worked

In your `ISE754` folder, start Claude Code and type `/review` with a lecture number. If the
command is not recognized, the skill is not where Claude Code can see it: check that
`ISE754/.claude/skills/review/SKILL.md` exists, and that you started Claude Code from
`ISE754` or a folder inside it.

Running `/review` on a lecture with no brief will say so and stop. That is correct
behavior, not a fault, and it means the review for that lecture has not been written yet.

## Where each skill reads from

The skills live here, in the public repository, because they are machinery rather than
course content: they contain no problems and no answers, and they need to be installable
from the repository the setup already cloned. What they *read* is a different matter.
`/review` reads its per-lecture brief from `ISE754/handouts/`, the private repository, since
a brief carries the planted error and its answer. So a skill can be installed before you
have handouts access, and will simply tell you when the thing it needs is not there yet.
