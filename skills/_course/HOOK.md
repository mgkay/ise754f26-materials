# The course hooks

**Two hooks, registered once, covering every course skill.** They cover `/review` and every
activity skill that arrives later — homework, project — because a record names its own
activity rather than each skill bringing its own machinery. Adding a skill never changes
what you install here.

## Registering them

In `ISE754/.claude/settings.json`, add both. If the file already has a `hooks` block, add
these entries to it rather than replacing it:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "julia .claude/skills/_course/record_activity.jl"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "julia .claude/skills/_course/check_sync.jl"
          }
        ]
      }
    ]
  }
}
```

The simplest way is to ask Claude Code, from inside your `ISE754` folder:

> Add both hooks from `materials/skills/_course/HOOK.md` to `.claude/settings.json`,
> preserving anything already there.

## What they do

**`record_activity.jl`, at the end of a session.** It looks for the structured record the
activity emitted, appends it as one line to `work/activity-log.jsonl`, and shows you a
reminder to commit and push. A session that was not a course activity emits no record, and
the hook does nothing.

The reminder is the point of it. The record lands in your own repository, so until you push,
nobody else can see it — an activity that is recorded but never pushed is, from the teaching
staff's side, an activity that did not happen. The hook has just written a line, so there is
always something to commit when you see the message.

**`check_sync.jl`, at the start of a session.** It reports two things, and says nothing at
all when there is nothing to report:

- **Commits pushed to your repository that you have not pulled.** This is how instructor
  feedback arrives, and during a project it is how the client's next data release arrives.
  It is listed first because it is the worse of the two: you are not merely behind, you may
  be working from something stale without knowing it.
- **Commits you made and never pushed**, which are still only on your machine and therefore
  not submitted.

It never reaches the network. It compares against whatever your last `git pull` or `git push`
left behind, so a session on a train is not slowed down and never hangs — running `git pull`
is what refreshes it.

## If they do not run

They are a convenience, not a gate. If Julia is not on the path or a file is missing, the
activity still works normally and only the record is lost; nothing about the session changes.
A record that could not be written leaves one line in `work/activity-log.error` saying why,
which is the first place to look if a session seems not to have counted.

## Notes on the design, for anyone reading the scripts

- A Stop hook's **stdout is written to the debug log and is not shown to you**, so its
  reminder is returned as a `systemMessage`, which the documentation describes as a warning
  message shown to the user.[^hooks]
- **`SessionStart` is different, and that is why the sync check lives there.** It is one of
  three events where Claude Code "adds plain-text stdout as context that Claude can see and
  act on", so a line printed at session start reaches you through the assistant's first
  turn.[^hooks] The same line printed from the Stop hook would reach nobody.
- Exit code 2 would block a session from ending and continue the conversation. It is
  deliberately not used: a hook that refuses to let a session end until a push succeeds
  traps anyone whose network or credentials are not working, and this is ungraded formative
  work.
- The sync check stays silent when there is nothing to say. It runs on every session,
  including ones with nothing to do with the course, and a hook that greets you every time
  is one you learn to ignore — which is exactly when it would stop working.

[^hooks]: Claude Code hooks reference, <https://code.claude.com/docs/en/hooks>, "Exit code
behavior" and the hook JSON output fields. Accessed 2026-08-16. Re-check these strings at
the start of each semester; hook behavior is the kind of thing that changes between
releases.
