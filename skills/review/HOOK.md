# The review recorder hook

The review skill records what you did so the class meeting can open on whatever the class
as a whole found hard. The record is written by a small script rather than by the assistant
remembering to save it, which is why it needs one entry in your settings.

## What to add

In `ISE754/.claude/settings.json`, add a `Stop` hook pointing at the recorder. If the file
already has a `hooks` block, add this entry to it rather than replacing it:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "julia .claude/skills/review/record_review.jl"
          }
        ]
      }
    ]
  }
}
```

Claude Code can make this edit for you, and that is the recommended route: ask it to add
the Stop hook from this file to `.claude/settings.json`, preserving anything already there.

## What it does, and what it does not

On the end of any session it looks for the structured block the review skill emits. If it
finds one, it appends it as a line to `review-log.jsonl` in your `work` repository, which
you commit like any other submission. If it does not find one, it does nothing at all, so
it is harmless on every session that was not a review.

**It never copies your conversation.** Only the structured record is written: which lecture,
the questions you asked, whether the big idea came up on its own, and whether you caught the
planted error. There is no name in it, because the repository it lands in is already yours.

**It runs on Julia**, which the course setup already installs, and uses only the standard
library, so it works whether or not the course environment has been instantiated. If the
hook cannot run, the review still works normally and only the record is lost; a
`review-log.error` file would appear in `work` saying why.
