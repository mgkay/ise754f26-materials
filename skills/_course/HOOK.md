# The course activity recorder hook

**One hook, for every course skill.** Registering it once covers `/review` and every
activity skill that arrives later — homework, project — because the record names its own
activity rather than each skill bringing its own recorder. Adding a skill never changes
what you install here.

## Registering it

In `ISE754/.claude/settings.json`, add a `Stop` hook pointing at the recorder. If the file
already has a `hooks` block, add this entry to it rather than replacing it:

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
    ]
  }
}
```

The simplest way is to ask Claude Code, from inside your `ISE754` folder:

> Add the Stop hook from `materials/skills/_course/HOOK.md` to `.claude/settings.json`,
> preserving anything already there.

## What it does

At the end of any session, it looks for the structured record the activity emitted, appends
it as one line to `work/activity-log.jsonl`, and shows you a reminder to commit and push.
A session that was not a course activity emits no record, and the hook does nothing.

**The reminder is the point of it.** The record lands in your own repository, so until you
push, nobody else can see it — an activity that is recorded but never pushed is, from the
teaching staff's side, an activity that did not happen. The hook has just written a line,
so there is always something to commit when you see the message.

## If it does not run

The hook is a convenience, not a gate. If Julia is not on the path or the file is missing,
the activity still works normally and only the record is lost; nothing about the session
changes. A record that could not be written leaves one line in `work/activity-log.error`
saying why, which is the first place to look if a session seems not to have counted.

## Notes on the design, for anyone reading the script

- A Stop hook's **stdout is written to the debug log and is not shown to you**, so the
  reminder is returned as a `systemMessage`, which the documentation describes as a warning
  message shown to the user.[^hooks]
- Exit code 2 would block the session from ending and continue the conversation. It is
  deliberately not used: a hook that refuses to let a session end until a push succeeds
  traps anyone whose network or credentials are not working, and this is ungraded formative
  work.

[^hooks]: Claude Code hooks reference, <https://code.claude.com/docs/en/hooks>, "Exit code
behavior" and the hook JSON output fields. Accessed 2026-08-16. Re-check these strings at
the start of each semester; hook behavior is the kind of thing that changes between
releases.
