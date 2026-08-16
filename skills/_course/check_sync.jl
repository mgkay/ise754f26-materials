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
# NEVER FETCHES. It compares against the last-known remote state, which is whatever the
# student's most recent pull or push left behind. Reaching the network at session start
# would add latency to every session and fail on a train; a stale "behind" reading is worth
# more than a hook that hangs. The student's own `git pull` refreshes it.

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
        out = read(Cmd(`git rev-list --count $range`; dir = work), String)
        return tryparse(Int, strip(out))
    catch
        return nothing   # no upstream configured yet, or not a repository
    end
end

function main()
    work = find_work_dir()
    work === nothing && return 0

    ahead = count_commits(work, "@{u}..HEAD")
    behind = count_commits(work, "HEAD..@{u}")

    lines = String[]
    if behind !== nothing && behind > 0
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

    isempty(lines) && return 0
    println("Course repository status, from the ISE 754 session-start check:")
    for l in lines
        println("- ", l)
    end
    return 0
end

exit(main())
