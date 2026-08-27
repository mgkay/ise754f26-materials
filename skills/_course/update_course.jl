#!/usr/bin/env julia
#
# Bring the read-only course repositories and the installed skills up to date, then say what
# changed. Every course activity skill runs this as its first step, so a student never has to
# know that an update exists.
#
# WHY THIS IS A SHARED SCRIPT AND NOT A STEP WRITTEN INTO EACH SKILL. Four skills are planned
# -- review, homework, study guide, project -- and the update rule is identical for all of
# them. Written four times it drifts four ways, and the first symptom of drift is a student
# running one activity on last week's material while another activity is current. The same
# reasoning HOOK.md gives for the two hooks: "adding a skill never changes what you install
# here."
#
# WHY IT ACTS INSTEAD OF REPORTING. `check_sync.jl` already reports staleness at session start
# and its report is correct, but a report puts the work on the student: pull two repositories,
# then re-run a copy step out of BOOTSTRAP that nobody remembers the number of. Measured on
# 2026-08-20, that instruction had never been followed in the reference tree -- zero of six
# lecture twins present, and an older `_course/check_sync.jl` installed. The instruction was
# right and it still did not happen. So this script does the pulling and the copying.
#
# THE ONE THING IT CANNOT DO, STATED PLAINLY. A skill's instructions are read when the skill is
# invoked. If this script replaces the very SKILL.md that is running, the replacement is on
# disk and the *running* session is still following the old text. There is no way around that
# from inside the session, so the script detects exactly that case and exits 10, and the skill
# is required to stop and ask for a restart rather than carry on. Everything else it changes --
# a lecture, a brief, a homework sheet, another skill -- is read after this step, so it takes
# effect immediately.
#
# WHAT IT NEVER DOES TO `work/`: any git operation. That repository is the student's own, it
# can hold uncommitted work, and pulling or merging it mid-session is how a student loses
# something. `check_sync.jl` reports on `work/` at session start and that is where it belongs.
# The two repositories this script pulls are the two the student never writes to.
#
# It does write ONE kind of file into `work/`: a copy of each published homework sheet, at
# `work/hw<N>/hw<N>-sheet.md`. That is a file creation, not a merge, and the rules it follows are
# in `mirror_homework` below. It never writes a submission filename and never overwrites
# anything the student has typed into.
#
# FAST-FORWARD ONLY, NEVER A MERGE. `materials/` and `handouts/` are read-only to a student, so
# a clone that cannot fast-forward means something is wrong -- an edited file, a committed
# experiment -- and the right response is to name it, not to resolve it. A merge commit in a
# student's materials clone is a problem that surfaces weeks later as a phantom conflict.
#
# OFFLINE IS NOT AN ERROR. Every network failure returns quietly and the activity continues on
# what is already on disk. A student on a train gets their homework. An update check that can
# block the work is worse than a stale skill, and this script is a convenience, not a gate.
#
# Exit codes:
#   0   nothing changed, or nothing could be checked. Safe to continue.
#   10  something changed. Continue -- UNLESS `--skill <name>` was given and that skill's own
#       files were among the changes, in which case the caller must stop and ask for a restart.
#       The report says which of the two it is, in those words.
#   1   a repository is in a state this script will not resolve. Report it and continue on what
#       is on disk; nothing has been broken, but something needs a person.
#   2   usage.

using SHA

const READONLY_REPOS = ("materials", "handouts")

# git's own stalled-transfer abort, about five seconds. macOS ships no timeout(1), and this is
# the mechanism check_sync.jl already uses for the same reason.
const NET = ["-c", "http.lowSpeedLimit=1000", "-c", "http.lowSpeedTime=5"]

"""
The `ISE754` folder: the one holding the read-only repositories side by side.

Walks up from the working directory, because a session moves into `work/` and `materials/`
many times and a skill can be invoked from any of them.
"""
function find_root()
    dir = abspath(pwd())
    while true
        if all(r -> isdir(joinpath(dir, r)), READONLY_REPOS) || isdir(joinpath(dir, "materials"))
            isdir(joinpath(dir, ".claude")) && return dir
        end
        parent = dirname(dir)
        parent == dir && return nothing
        dir = parent
    end
end

"Run a git command in `dir`, capturing everything. Never throws."
function git(dir, args...)
    out = IOBuffer()
    err = IOBuffer()
    try
        p = run(pipeline(Cmd(`git $(collect(args))`; dir = dir); stdout = out, stderr = err);
                wait = true)
        return (code = p.exitcode, out = String(take!(out)), err = String(take!(err)))
    catch e
        return (code = -1, out = String(take!(out)),
                err = e isa ProcessFailedException ? String(take!(err)) : string(e))
    end
end

"""
Fast-forward one read-only repository. Returns a symbol and a count of new commits.

`:absent`   the folder is not a clone. The bootstrap creates `handouts/` empty on purpose, so
            this is the normal state for a student who has not cloned it yet, and it is not an
            error here -- the skill that needs the file will say so in its own words.
`:offline`  the remote could not be reached. Silent by design.
`:diverged` a fast-forward is not possible, or a local change is in the way. Needs a person.
`:ok`       up to date or fast-forwarded; the count says how many commits arrived.
"""
function ff_pull(repo)
    isdir(joinpath(repo, ".git")) || return (:absent, 0)

    before = strip(git(repo, "rev-parse", "HEAD").out)
    r = git(repo, NET..., "pull", "--ff-only")
    after = strip(git(repo, "rev-parse", "HEAD").out)

    if r.code != 0
        # Distinguish "could not reach the remote" from "will not fast-forward", because the
        # first must be silent and the second must be said out loud. The two are separated by
        # ASKING THE REMOTE, not by reading git's error text.
        #
        # An earlier version matched a list of phrases -- "could not resolve", "unable to
        # access", and so on -- and the self-test killed it: a remote that is simply not there
        # produces none of them, so a broken remote was reported to the student as "something
        # has been changed or committed inside it", which is a false accusation about their own
        # work. Any phrase list is an allowlist, and the case it misses always fails toward the
        # accusation.
        #
        # `ls-remote` writes no ref and fetches no object, and it only runs on this failure
        # path. If it cannot reach the remote either, the pull failed for a reason outside the
        # student's control, and this script says nothing. If it CAN reach the remote, the pull
        # failed locally and that is worth a sentence.
        reachable = git(repo, NET..., "ls-remote", "--exit-code", "origin", "HEAD").code == 0
        return (reachable ? :diverged : :offline, 0)
    end

    before == after && return (:ok, 0)
    n = tryparse(Int, strip(git(repo, "rev-list", "--count", "$before..$after").out))
    return (:ok, something(n, 0))
end

"""
Copy every shipped skill folder into `.claude/skills/`, returning the relative paths written.

This is BOOTSTRAP Step 7a, performed rather than recommended. It writes a file only when the
content actually differs, so the return value is a true list of what changed and an unchanged
tree reports nothing.

It does NOT delete anything. A file that exists only in the installed copy is left alone: this
script has no way to tell a withdrawn skill from a student's own experiment, and deleting from
somebody's `.claude/` to save them a stale file is the wrong trade.
"""
function install_skills(root)
    # SKILLS SHIP FROM HANDOUTS, not from this repository. Moved 2026-08-27 so a
    # skill revision no longer needs a merge here. handouts is already in
    # READONLY_REPOS above and already fast-forwarded on every invocation, students
    # already clone it, and the TA has push on it. A student's setup is unchanged.
    src = joinpath(root, "handouts", "skills")
    dst = joinpath(root, ".claude", "skills")
    isdir(src) || return String[]
    mkpath(dst)

    written = String[]
    for entry in readdir(src)
        sdir = joinpath(src, entry)
        isdir(sdir) || continue                        # README.md is not a skill
        ddir = joinpath(dst, entry)
        mkpath(ddir)
        for f in readdir(sdir)
            sf = joinpath(sdir, f)
            isfile(sf) || continue                     # one level; no skill nests today
            df = joinpath(ddir, f)
            if !isfile(df) || read(sf) != read(df)
                cp(sf, df; force = true)
                # FORWARD SLASH DELIBERATELY, not joinpath. This list is COMPARED against
                # `skill * "/"` at the running_stale decision below, so a separator that
                # varies by platform makes that comparison platform-dependent. On Windows
                # joinpath gives `homework\\SKILL.md`, startswith(..., "homework/") is false,
                # and the STOP block never prints -- so a Windows student whose SKILL.md was
                # just replaced is told nothing and carries on following the old text, which
                # is the one case the header of this file says must stop. Reported by
                # Dr. Kay 2026-08-26 from a Windows run: test_update_course 73/76 there
                # against 76/76 on macOS, and the third failure was this guarantee.
                push!(written, entry * "/" * f)
            end
        end
    end
    return written
end


const HDR_END = "<!-- end ise754 header -->"

"""
Which published homework sheets are mirrored, by extension.

The sheets are `hw<N>.<ext>` in `handouts/homework/`, and each is copied to
`work/hw<N>/hw<N>-sheet.<ext>`. Only the extension list is configurable: the destination is
derived from the `<N>` and there is nothing to choose about it.

WHY A LIST AND NOT A GUESS. Every sheet is markdown today, deliberately, so a student can hand
it straight to their assistant while the solution stays a PDF they have to read themselves. The
publishing manifest's own worked examples name `homework/hw1.pdf`, so a non-markdown sheet is a
live possibility rather than a hypothetical -- but which extensions get used is the
instructor's decision and not something to infer from one semester's practice.

To change it, put one extension per line in `_course/mirror_extensions.txt`, `#` for comments.
Absent or unreadable, the default below applies.
"""
const MIRROR_EXTS_DEFAULT = ["md"]

"""
Companion documents copied into EVERY homework folder, not just the one they were added for.

The instructor's design, 2026-08-25: "we could attach each homework ... these are all the
formulas and stuff that are going to be on your exam ... a third page would be stapled, which
would be the formula sheet for the exam", and on whether it resets per exam, "you probably
should just do a cumulative ... we're basically just append new things to a single standalone
document."

So it is ONE cumulative file that grows through the semester, and it belongs beside every
homework rather than only the latest, because a student opening `work/hw2/` to revise for the
second assessment needs the sheet as much as one opening `work/hw5/`. Copying it into each
folder costs a few kilobytes and makes each folder self-contained, which is what "attach each
homework" means in practice.

**The default name is a default, not a fact.** The file does not exist yet: the formula sheet
is the instructor's to write and has not been published. Until it is, this list matches nothing
and nothing is copied, which is the correct behaviour rather than a failure. If he publishes it
under another name, put that name in `_course/mirror_companions.txt`, one per line, and no code
changes.
"""
const MIRROR_COMPANIONS_DEFAULT = ["formulas.md"]

function mirror_companions()
    f = joinpath(@__DIR__, "mirror_companions.txt")
    isfile(f) || return MIRROR_COMPANIONS_DEFAULT
    names = String[]
    for line in eachline(f)
        t = strip(first(split(line, "#")))
        isempty(t) && continue
        push!(names, t)
    end
    return isempty(names) ? MIRROR_COMPANIONS_DEFAULT : names
end

function mirror_exts()
    f = joinpath(@__DIR__, "mirror_extensions.txt")
    isfile(f) || return MIRROR_EXTS_DEFAULT
    exts = String[]
    for line in eachline(f)
        t = strip(first(split(line, "#")))
        isempty(t) && continue
        push!(exts, lowercase(lstrip(t, '.')))
    end
    return isempty(exts) ? MIRROR_EXTS_DEFAULT : exts
end

"""
Copy every published homework sheet into the student's own folder, and keep the copy current.

WHY A COPY AT ALL. The sheet is published to `handouts/`, which is a different repository from
the one the student works in. Nothing is wrong with reading it there, but a student starts by
making a folder and looking for the questions, and the folder they will submit from is the
obvious place for them to be. So each published `handouts/homework/hw<N>.md` is mirrored to
`work/hw<N>/hw<N>-sheet.md`, and the folder the submission goes in exists from the moment the
homework is published.

WHY NOT `work/hw<N>/hw<N>.md`. That is the submission filename. `HOMEWORK.md` says the answers
go in `hw<N>.md`, so writing the questions there would hand the student a file that is
simultaneously the sheet and the answer sheet, and their submission would arrive with the
questions embedded in it. `-sheet` keeps the two apart, and the header says which is which in
the first line, because the filename alone will not stop someone from typing into it.

WHY IT IS NOT A TEMPLATE. Only the sheet, verbatim, plus a header. No headings to fill in, no
stub script, no question numbers pre-laid-out. The instructor's rule: a skeleton is the
beginning of an answer, and these sheets are written so that working out which method applies
is part of the work.

WHY IT REFRESHES, AND HOW IT AVOIDS EATING SOMEBODY'S WORK. A homework sheet gets corrected --
HW 1 existed in two disagreeing versions before it was published -- and a stale private copy of
a corrected sheet is worse than no copy, because nothing about it looks stale. So the copy is
rewritten whenever the source changes. The danger in that is obvious: refresh a file a student
has typed into and their work is gone, with no git history to recover it from if it was never
committed.

The header therefore stamps the sha256 of the body as written. On every run the body is hashed
again: if it matches, this is still our untouched copy and replacing it loses nothing. If it
does not match, the student has edited the file and it is left exactly as it is, and the caller
is told. There is no flag to force it.

Returns (written, protected): paths refreshed, and paths left alone because they were edited.
"""
function mirror_homework(root)
    src = joinpath(root, "handouts", "homework")
    work = joinpath(root, "work")
    (isdir(src) && isdir(work)) || return (String[], String[])

    written = String[]
    protected = String[]

    exts = mirror_exts()
    pat = Regex("^(hw\\d+)\\.(" * join(exts, "|") * ")\$", "i")

    for f in sort(readdir(src))
        m = match(pat, f)
        m === nothing && continue
        hw, ext = m.captures[1], lowercase(m.captures[2])
        dest = joinpath(work, hw, "$hw-sheet.$ext")

        if ext != "md"
            # A non-text sheet cannot carry a header, so there is nowhere to stamp the hash
            # that tells our untouched copy from one the student has annotated. Copy it if it
            # is absent; if it is present and differs, say so and change nothing. Guessing
            # wrong in the other direction would overwrite somebody's marked-up PDF.
            raw = read(joinpath(src, f))
            if !isfile(dest)
                mkpath(dirname(dest)); write(dest, raw)
                push!(written, relpath(dest, root))
            elseif read(dest) != raw
                push!(protected, relpath(dest, root))
            end
            continue
        end

        body = read(joinpath(src, f), String)
        digest = bytes2hex(sha256(body))

        if isfile(dest)
            existing = read(dest, String)
            i = findfirst(HDR_END, existing)
            if i === nothing
                # No header: not a file this script wrote. Never touch it.
                push!(protected, relpath(dest, root)); continue
            end
            here = lstrip(existing[(last(i) + 1):end], '\n')
            stamp = match(r"body-sha256:\s*([0-9a-f]{64})", existing[1:last(i)])
            if stamp === nothing || bytes2hex(sha256(here)) != stamp.captures[1]
                push!(protected, relpath(dest, root)); continue   # edited by the student
            end
            bytes2hex(sha256(here)) == digest && continue          # already current
        end

        header = """
        <!-- ise754: a COPY of handouts/homework/$f. Read it here; do not answer here. -->
        <!-- Your answers go in $hw.md and your script in $hw.jl, in this same folder. -->
        <!-- See handouts/homework/HOMEWORK.md for what to submit and how. -->
        <!-- Refreshed automatically while this file is unedited. Edit it and it is left alone. -->
        <!-- body-sha256: $digest -->
        $HDR_END

        """
        mkpath(dirname(dest))
        write(dest, replace(header, r"^ +"m => "") * body)
        push!(written, relpath(dest, root))
    end
    # Companions go into every homework folder that now exists. Same hash-stamped refresh as a
    # sheet, so a corrected formula sheet reaches the student and an annotated one is left
    # alone. Runs after the sheet pass so the folders are already there.
    hw_dirs = sort([d for d in (isdir(work) ? readdir(work) : String[])
                    if occursin(r"^hw\d+$", d) && isdir(joinpath(work, d))])
    for name in mirror_companions()
        srcf = joinpath(src, name)
        isfile(srcf) || continue
        body = read(srcf, String)
        digest = bytes2hex(sha256(body))
        for hw in hw_dirs
            dest = joinpath(work, hw, name)
            if isfile(dest)
                existing = read(dest, String)
                i = findfirst(HDR_END, existing)
                if i === nothing
                    push!(protected, relpath(dest, root)); continue
                end
                here = lstrip(existing[(last(i) + 1):end], '\n')
                stamp = match(r"body-sha256:\s*([0-9a-f]{64})", existing[1:last(i)])
                if stamp === nothing || bytes2hex(sha256(here)) != stamp.captures[1]
                    push!(protected, relpath(dest, root)); continue
                end
                bytes2hex(sha256(here)) == digest && continue
            end
            header = """
            <!-- ise754: a COPY of handouts/homework/$name, refreshed automatically. -->
            <!-- This is the sheet you will have in front of you for the in-class assessment. -->
            <!-- Edit it and it is left alone, and then it stops being refreshed. -->
            <!-- body-sha256: $digest -->
            $HDR_END

            """
            mkpath(dirname(dest))
            write(dest, replace(header, r"^ +"m => "") * body)
            push!(written, relpath(dest, root))
        end
    end

    return (written, protected)
end

function main(argv)
    skill = nothing
    i = 1
    while i <= length(argv)
        if argv[i] == "--skill" && i < length(argv)
            skill = argv[i + 1]; i += 2
        elseif argv[i] == "--self-test"
            println("Self-test lives in test_update_course.jl beside this file.")
            return 2
        else
            println(stderr, "usage: update_course.jl [--skill <name>]")
            return 2
        end
    end

    root = find_root()
    if root === nothing
        println("Course folder not found from here, so nothing was checked. " *
                "Continue on what is on disk.")
        return 0
    end

    lines = String[]
    problems = String[]
    changed = false

    for repo in READONLY_REPOS
        state, n = ff_pull(joinpath(root, repo))
        if state == :ok && n > 0
            changed = true
            push!(lines, "$repo: $n new commit$(n == 1 ? "" : "s") pulled.")
        elseif state == :diverged
            push!(problems,
                  "$repo cannot be fast-forwarded. It is a read-only copy, so something has " *
                  "been changed or committed inside it. Nothing was pulled and nothing was " *
                  "lost. Run `git -C $repo status` to see what is in the way.")
        end
        # :absent and :offline say nothing, on purpose.
    end

    mirrored, kept = mirror_homework(root)
    if !isempty(mirrored)
        changed = true
        push!(lines, "homework sheets copied into work/: " * join(mirrored, ", "))
    end
    for k in kept
        push!(lines, "$k was edited, so it was left alone and NOT refreshed. The published " *
                     "sheet may have changed since. Compare it against handouts/homework/.")
    end

    installed = install_skills(root)
    if !isempty(installed)
        changed = true
        push!(lines, "skills reinstalled: " * join(sort(installed), ", "))
    end

    running_stale = skill !== nothing &&
                    any(p -> startswith(p, skill * "/"), installed)

    for l in lines; println(l); end
    for p in problems; println(p); end

    if running_stale
        println()
        println("THE INSTRUCTIONS FOR /$skill WERE JUST REPLACED. This session is still " *
                "following the previous version. Stop here, ask the student to restart " *
                "Claude Code, and have them run /$skill again. Do not continue the activity.")
        return 10
    end

    !isempty(problems) && return 1
    changed && return 10
    return 0
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    exit(main(ARGS))
end
