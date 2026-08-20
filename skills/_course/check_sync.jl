#!/usr/bin/env julia
#
# SessionStart hook: report work that has not been pushed, and releases that have not been
# pulled. Runs at the start of every Claude Code session.
#
# WHY SessionStart AND NOT Stop. A Stop hook's stdout goes to the debug log and is not shown
# to anyone (Claude Code hooks documentation, "Exit code behavior"; accessed 2026-08-16).
# SessionStart is one of three events where Claude Code "adds plain-text stdout as context
# that Claude can see and act on", so a line printed here reaches the student through the
# assistant's first turn. That is the only reliable route for a reminder that has to arrive
# when the student is not already being told something.
#
# WHY BOTH DIRECTIONS. They are the same check with the arguments swapped, and each catches
# a different failure that neither the student nor the instructor sees until too late:
#
#   AHEAD   commits the student made and never pushed. Their work exists only on their
#           machine, so a deadline passes with nothing submitted and no sign of trouble.
#
#   BEHIND  commits pushed INTO their repository that they never pulled: instructor
#           feedback, and, during a project, the client's next data release. The project
#           record states the consequence plainly -- "a release pushed that the student
#           never pulls is a dead project" -- and it is the worse of the two, because the
#           student is not merely late, they are working from a stale brief and do not know
#           it.
#
# QUIET WHEN THERE IS NOTHING TO SAY. This fires on every session, including sessions that
# have nothing to do with the course, so it prints only when there is something actionable
# and never explains itself otherwise. A hook that greets every session teaches people to
# ignore it, and it would be ignored precisely when it finally mattered.
#
# WORK/ NEVER FETCHES. The two counts above compare against the last-known remote state,
# whatever the student's most recent pull or push left behind. Reaching the network for them
# would add latency to every session and fail on a train; a stale "behind" reading is worth
# more than a hook that hangs. The student's own `git pull` refreshes it.
#
# MATERIALS/ IS THE ONE EXCEPTION, AND IT IS DELIBERATE. Nothing a student does updates their
# knowledge of the materials remote, so a purely local check cannot tell that the instructor
# published anything. That is not hypothetical: on 2026-08-20 the reference student tree held
# zero of the six lecture .md twins on main, and an older _course/check_sync.jl, because
# nothing had ever prompted a pull. The review activity reads materials/lectures/<stem>.md,
# so the student meets a degraded activity and no one is told.
#
# The cost is bounded three ways rather than by a promise. `git ls-remote` mutates no ref and
# fetches no object; it asks for one sha. `http.lowSpeedLimit`/`http.lowSpeedTime` abort a
# stalled transfer in about five seconds, which is git's own mechanism and needs no timeout(1)
# (macOS ships none). And every failure path returns `nothing` and prints, so offline, slow,
# and no-remote are all silent rather than noisy. A student on a train sees exactly what they
# see today.

const WORK_HINT = "work"

"The student's work repository, or nothing if this session is not near one."
function find_work_dir()
    dir = pwd()
    while true
        work = joinpath(dir, WORK_HINT)
        isdir(joinpath(work, ".git")) && return work
        basename(dir) == WORK_HINT && isdir(joinpath(dir, ".git")) && return dir
        parent = dirname(dir)
        parent == dir && return nothing
        dir = parent
    end
end

"Count from `git rev-list`, or nothing when there is no upstream to compare against."
function count_commits(work, range)
    try
        # stderr to devnull: see the note in record_activity.jl. A repository with no
        # upstream otherwise prints git's "fatal:" twice at session start, once per check.
        cmd = pipeline(Cmd(`git rev-list --count $range`; dir = work), stderr = devnull)
        out = read(cmd, String)
        return tryparse(Int, strip(out))
    catch
        return nothing   # no upstream configured yet, or not a repository
    end
end

"The ISE754 folder that holds `work`, or nothing."
find_root(work) = (r = dirname(work); isdir(joinpath(r, "materials")) ? r : nothing)

"""
Do the installed skills differ from the ones shipped in `materials/skills/`?

Network-free and cheap. This is the second half of the delivery path: BOOTSTRAP Step 7a says
to re-run the copy "after any `git pull` in materials/ that reports a change under skills/",
and that instruction is correct, but nothing checks it afterwards. A student who pulls and
forgets keeps running the old skill, and the tree looks healthy.

`true` if any shipped skill folder is missing from `.claude/skills/` or differs byte for byte.
"""
function skills_stale(root)
    src = joinpath(root, "materials", "skills")
    dst = joinpath(root, ".claude", "skills")
    (isdir(src) && isdir(dst)) || return nothing
    for entry in readdir(src)
        sdir = joinpath(src, entry)
        isdir(sdir) || continue                      # README.md is not a skill
        ddir = joinpath(dst, entry)
        isdir(ddir) || return true                   # shipped but never installed
        for f in readdir(sdir)
            sf = joinpath(sdir, f)
            isfile(sf) || continue
            df = joinpath(ddir, f)
            (isfile(df) && read(sf) == read(df)) || return true
        end
    end
    return false
end

"""
Has `materials` moved on the remote since this clone last pulled?

One `ls-remote`: no ref is written, no object is fetched. Bounded by git's own low-speed abort
so it cannot hang. Returns `nothing` whenever the answer is unknown for any reason, which is
the offline case and is silent by design.
"""
function materials_behind(root)
    mats = joinpath(root, "materials")
    isdir(joinpath(mats, ".git")) || return nothing
    remote = try
        cmd = pipeline(Cmd(`git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=5 ls-remote --heads origin main`; dir = mats),
                       stderr = devnull)
        out = read(cmd, String)
        isempty(strip(out)) ? nothing : first(split(strip(out)))
    catch
        nothing
    end
    remote === nothing && return nothing
    here = try
        strip(read(pipeline(Cmd(`git rev-parse HEAD`; dir = mats), stderr = devnull), String))
    catch
        nothing
    end
    here === nothing && return nothing
    return remote != here
end

"""
Has anything been pushed into the student's OWN repository that they do not have?

WHY `@{u}` IS NOT ENOUGH, and why this file's own BEHIND check could not do its job. The
BEHIND check compares HEAD against `@{u}`, the remote-tracking ref, and that ref only moves
on a fetch or a pull. So the instant a TA pushes feedback, the student's `HEAD..@{u}` is
still 0 and stays 0 until the student pulls -- which is the very thing the warning exists to
prompt. The check could only ever fire AFTER the student had already done the thing it was
telling them to do.

Measured 2026-08-20 with two feedback commits sitting on the remote: `HEAD..@{u}` returned
0, `ls-remote` returned a sha the clone had never seen, and the session-start check said
nothing at all about feedback.

This file's header calls the BEHIND case the worse of the two, because a student working
from a stale brief is not merely late. So this asks the remote, the same way
`materials_behind` does: one sha, no ref written, no object fetched. Every failure path
returns nothing and stays silent.
"""
function work_behind(work)
    remote = try
        cmd = pipeline(Cmd(`git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=5 ls-remote --heads origin main`; dir = work),
                       stderr = devnull)
        out = read(cmd, String)
        isempty(strip(out)) ? nothing : first(split(strip(out)))
    catch
        nothing
    end
    remote === nothing && return nothing
    # Reachable from HEAD means we already have it; not reachable means it is new to us.
    try
        run(pipeline(Cmd(`git merge-base --is-ancestor $remote HEAD`; dir = work), stderr = devnull))
        return false
    catch
        return true
    end
end

function main()
    work = find_work_dir()
    work === nothing && return 0

    ahead = count_commits(work, "@{u}..HEAD")
    behind = count_commits(work, "HEAD..@{u}")

    lines = String[]
    # Ask the remote first. `behind` (from @{u}) cannot see a push that has just happened,
    # so it is kept only as the offline fallback.
    remote_has_new = work_behind(work)
    if remote_has_new === true
        push!(lines,
            "The student's work repository has commits on GitHub that this clone does NOT " *
            "have. This is how instructor feedback and project data releases arrive, so " *
            "they may be working from something stale. Tell them to run " *
            "`git pull --no-rebase` from their ISE754/work folder before going further.")
    elseif behind !== nothing && behind > 0
        push!(lines,
            "$behind commit(s) have been pushed to the student's work repository that they " *
            "have NOT pulled. This is how instructor feedback and project data releases " *
            "arrive, so they may be working from something stale. Tell them to run " *
            "`git pull` from their ISE754/work folder before going further.")
    end
    if ahead !== nothing && ahead > 0
        push!(lines,
            "$ahead commit(s) in the student's work repository have NOT been pushed. " *
            "Work that is committed but not pushed has not been submitted, because it is " *
            "still only on their machine. Tell them to run `git push` from ISE754/work.")
    end

    root = find_root(work)
    if root !== nothing
        moved = materials_behind(root)
        if moved === true
            push!(lines,
                "The course `materials` repository has commits this clone does not have. That " *
                "is how new lectures, their companion scripts and the course skills arrive, " *
                "and an activity that reads one of them will quietly work from something older " *
                "or report it missing. Tell them to run `git pull` in ISE754/materials.")
        end
        if skills_stale(root) === true
            push!(lines,
                "The course skills in `.claude/skills/` no longer match the ones in " *
                "`materials/skills/`, so this session is running an older copy than the one " *
                "shipped. Re-run BOOTSTRAP Step 7a: copy every FOLDER in `materials/skills/` " *
                "into `.claude/skills/`. Copying the folders' contents instead leaves no " *
                "loadable skill at all, so check that `.claude/skills/review/SKILL.md` exists " *
                "afterwards.")
        end
    end

    isempty(lines) && return 0
    println("Course repository status, from the ISE 754 session-start check:")
    for l in lines
        println("- ", l)
    end
    return 0
end

exit(main())
