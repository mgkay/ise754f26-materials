# ISE 754 — Submitting your work

**Fall 2026.** Coursework is submitted as code, in a private repository on GitHub that belongs to
you. This page sets that up once and then describes the routine, which is three commands before
each class meeting.

Set this up **before 8:00 pm Eastern on Monday, August 24**, when the first submission is due, for
the class meeting the next morning. Everything here assumes
the toolchain from [SETUP.md](SETUP.md) is working and the check reported `READY`.

The GitHub and single sign-on behaviour described below was taken from official documentation on
**2026-08-13** and is cited at the end.

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

Replace `<unityid>` with yours, in lower case. Only you, the instructor, the teaching assistant, and
NC State IT administrators can read it.

> ⚠ **If the address gives "not found" or "repository does not exist," the repository is not ready
> yet rather than lost.** Try one thing first: if your credential has not been through NC State
> single sign-on, GitHub hides a private repository rather than reporting a permissions error, so an
> account that *does* have access still sees "not found." Sign in at github.com, complete single
> sign-on, and reload the address before assuming anything is missing. If it still does not appear,
> getting you access takes two steps and the first can only be done by an organization owner at NC
> State IT, so a student who added the course late may wait a day or two.
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

The repository is private and it sits inside an NC State organization, so git has to establish who
you are twice over. On the first clone a browser window opens: sign in to GitHub, and then pass
**NC State single sign-on**, the same login used for other university services.<sup>[1]</sup><sup>[3]</sup>
Both are needed, because access to a repository in this organization is granted only to a credential
that has been through single sign-on.

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

**Work is due at 8:00 pm Eastern on the evening before the class meeting at which it is assessed.**
That is an absolute time, the same for both sections, and it is when submissions are collected and
reviewed together to prepare the next morning's class. Anything pushed later is not in that set.

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
you do not have. Run `git pull --no-rebase`, then push again. The flag matters: without it, git on
macOS stops with "Need to specify how to reconcile divergent branches" instead of merging, and the
push stays rejected.

**A push or pull fails days after a clone that worked, and the message sounds like a permission
problem.** The single-sign-on session has almost certainly expired rather than access having been
removed: that login lasts 24 hours unless NC State sets it differently.<sup>[3]</sup> Signing in
again restores it, so try that before assuming something is broken. This is the failure most likely
to look alarming and mean nothing, because nothing about the wording says "sign in again."

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
3. [About authentication with single sign-on](https://docs.github.com/en/enterprise-cloud@latest/authentication/authenticating-with-single-sign-on/about-authentication-with-single-sign-on)
   — that git over HTTPS against an organization using single sign-on requires a credential that has
   been authorized for it, and that the login period is 24 hours unless the identity provider sets
   it otherwise.
