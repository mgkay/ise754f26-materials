# ISE 754 — Submitting your work

**Fall 2026.** Coursework is submitted as code, in a private repository on GitHub that belongs to
you. This page sets that up once and then describes the routine, which is three commands before
each class meeting.

Set this up **before Tuesday August 25**, when the first submission is due. Everything here assumes
the toolchain from [SETUP.md](SETUP.md) is working and the check reported `READY`.

Every command, menu name, and link below was taken from official documentation on **2026-08-13** and
is cited at the end.

---

## Why code and not an upload

The course asks you to build, read, and verify computational models, so the work *is* code. A
repository also keeps the history of how you got there, which an upload cannot: a file shows what
you concluded, and the history shows what you tried. Both get looked at.

---

## Step 0 — Your repository already exists

**You do not create it.** Teaching staff create one private repository per student, named after your
Unity ID:

```
https://github.com/ncstate-engr-ise/ise754-f26-<unityid>
```

Replace `<unityid>` with yours, in lower case. Only you, the instructor, and the teaching assistant
can see it.

> ⚠ **If the address gives "not found" or "repository does not exist," the repository is not ready
> yet rather than lost.** Getting you access takes two steps and the first can only be done by an
> organization owner at NC State IT, so a student who added the course late may wait a day or two.
> **Email me rather than working around it.** Do not create a repository of your own to submit
> from; it cannot be graded, because the tooling that collects submissions only reads the
> organization's repositories.

---

## Step 1 — Clone it, once

From inside your `ISE754` folder, so that `work` lands beside `materials`:

**Windows:**

```powershell
cd $env:USERPROFILE\Documents\ISE754
git clone https://github.com/ncstate-engr-ise/ise754-f26-<unityid> work
```

**macOS:**

```bash
cd ~/Documents/ISE754
git clone https://github.com/ncstate-engr-ise/ise754-f26-<unityid> work
```

You should end with the two folders side by side, neither inside the other:

```
ISE754/
├── materials/     the course repository, you read it
└── work/          your repository, you write it
```

### What happens the first time, and why the email is not a breach

The repository is private, so git has to establish who you are. On the first clone a browser window
opens and asks you to sign in to GitHub.<sup>[1]</sup> Sign in with the account that has access to
your course repository.

**GitHub will then email you** to say that "a first-party GitHub OAuth application has been added to
your account," listing permissions including `repo`.<sup>[2]</sup> **That email is expected and is
not a sign that anything has gone wrong.** It is Git Credential Manager, the credential helper that
ships with Git, recording that you authorized it to act on your behalf so that you are not asked for
a password on every push. It is a GitHub application rather than a third-party one, which is why no
administrator has to approve it.

If you would rather not leave that authorization in place after the semester, it can be revoked in
your GitHub account settings under **Applications**.<sup>[2]</sup>

---

## Step 2 — What goes in it

Each assignment says what it expects. In general:

- **Your Julia scripts**, the actual files you ran, not a copy pasted into a document.
- **Anything the assignment names**, such as a short written answer or a session note.

Two things do **not** belong in it:

- **Anything under `materials/`.** That folder is a clone you pull; edits there are lost on the next
  update and are not part of your submission. Work in `work/`.
- **Large data files you did not create.** If an assignment supplies data, it is already in
  `materials/` and does not need copying.

---

## Step 3 — The routine, before each class meeting

Three commands, from inside `work`:

```bash
git add -A
git commit -m "HW 2: minisum for the eight demand points"
git push
```

`add` stages what changed, `commit` records it with a message, and `push` sends it to GitHub, which
is the point at which it counts as submitted. **Work that is committed but not pushed has not been
submitted**, because it is still only on your machine.

**Commit as you go rather than once at the end.** The history is part of what is looked at, and a
single commit of everything an hour before class shows less about your work than five commits over
two days. Write messages that say what changed, not "update."

**Submissions are collected the evening before each class meeting.** Anything pushed after that is
not in the set that gets reviewed together in class.

You can ask Claude Code to run these commands for you, and it will. **You are answerable for what is
in the commit either way**, which is the same standard the rest of the course uses: the tool does the
work, and you check it before it goes out.

---

## Confirming a submission landed

Two checks, and the second is the one that matters:

```bash
git status
```

should report nothing left to commit and that your branch is up to date with `origin`. Then **open
your repository in a browser** and look at it. The files you expect should be there, with the commit
message you wrote and a timestamp before the deadline. A push that failed silently looks exactly
like a push that worked until you look.

---

## When something goes wrong

**`git push` is rejected.** Someone, most likely the instructor leaving feedback, has added a commit
you do not have. Run `git pull`, then push again.

**"Authentication failed" or the browser sign-in never appears.** Ask Claude Code, quoting the exact
message. If it cannot resolve it, email me: an access problem is mine to fix, not yours to work
around.

**You committed something you should not have**, such as a large file or a password. Say so rather
than trying to erase it. Git history is designed to be hard to rewrite, and the fix is different
depending on what was committed and whether it has been pushed.

**Do not use `git push --force`.** It can delete work already submitted, including feedback, and
nothing in this course needs it.

---

## Sources

Taken from these pages on **2026-08-13**.

1. [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager) — the
   credential helper bundled with Git for Windows, which performs the browser sign-in on first
   access to a private repository.
2. [Reviewing and revoking authorization of GitHub Apps](https://docs.github.com/en/apps/using-github-apps/reviewing-and-revoking-authorization-of-github-apps)
   — that authorizing an application is recorded on the account and notified by email, and how to
   review or revoke it from account settings.

---

## Notes for review — delete before this reaches students

**The repository URL is the one thing not verified**, because the student repositories do not exist
yet. `ncstate-engr-ise/ise754-f26-<unityid>` is the naming settled in
`github-guidelines-ise754.md` Sec. 6, where it also records that "confirmation that no other
convention applies is still outstanding." **Check one real repository resolves before this page is
posted.**

**The credential-helper email warning is the most valuable paragraph here** and it is verified: the
guidelines record that on 2026-08-04 a first clone authorized Git Credential Manager with `gist`,
`repo`, and `workflow` scopes and GitHub emailed accordingly, with the note that every student will
receive it and "will read it as a security incident unless told beforehand." Not stating it in
advance guarantees a wave of alarmed email in week two.

**Deliberately not covered:** branching, merging, pull requests, `.gitignore`. None is needed to
submit, and each would be length without use. The feedback path is the instructor committing to the
student's repository, which is why `git pull` before pushing is in the troubleshooting list.

**Two dependencies before 8/25.** The organization must have added every enrolled student, which is
ITECS's step and cannot be done by teaching staff; and the per-student repositories must exist. The
late-add case is called out in Step 0 because the guidelines flag it as clustering exactly during
add and drop.

**Unresolved:** whether a "structured session log" is a named submission artifact. Sec. 6 of the
guidelines lists submitted work as "Julia scripts and structured session logs," but no assignment
defines the latter yet. Step 2 says "anything the assignment names" rather than inventing a format.
It may be the handoff note from Lecture 1.2 Sec. 2.12, in which case the two should use one name.
