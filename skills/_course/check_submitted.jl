#!/usr/bin/env julia
#
# "Can the teaching staff see my work?" -- run by the student, on demand.
#
#   julia .claude/skills/_course/check_submitted.jl
#
# WHY THIS EXISTS, AND WHY check_sync.jl IS NOT IT. check_sync.jl answers a different
# question and answers it deliberately offline: it compares HEAD against `@{u}`, the
# last-known remote state left behind by the student's own most recent pull or push, and
# never touches the network. That is right for a hook that fires on every session.
#
# It is NOT enough for the question a student actually worries about the night a deadline
# passes, which is not "does my machine think I pushed" but "is it THERE". Those come apart
# in the case that matters: a push that appeared to work, or a commit made on a branch
# nobody reads, leaves a local repository perfectly happy while GitHub has nothing. The
# course tells students that work committed but not pushed has not been submitted; this is
# the tool that lets them confirm the second half rather than take it on faith.
#
# SO THIS ONE ASKS THE SERVER. `git ls-remote` returns the remote's sha and nothing else:
# it writes no ref, fetches no object, and changes nothing locally. It is the same move
# check_sync.jl's materials check uses.
#
# NO timeout(1) WRAPPER. macOS does not ship `timeout`, so the bound is git's own
# http.lowSpeedLimit / http.lowSpeedTime. Every failure path -- offline, no remote, a
# repository that is not a repository -- returns nothing, says so in plain words, and exits
# 0. A student on a train gets "could not reach GitHub", never a hang and never a crash.
#
# IT NEVER WRITES ANYTHING. Reading only. A tool whose job is to reassure must not be
# capable of changing what it is reporting on.

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

"Run a git command in `work`. Returns (ok, stripped stdout); ok=false on any failure."
function git_try(work, args...)
    try
        cmd = pipeline(Cmd(`git $(collect(args))`; dir = work), stderr = devnull)
        return (true, strip(read(cmd, String)))
    catch
        return (false, "")
    end
end

"Stripped stdout, or nothing when the command failed OR produced nothing."
function git(work, args...)
    ok, out = git_try(work, args...)
    (ok && !isempty(out)) ? out : nothing
end

"""
The remote's sha for the default branch, WITHOUT fetching.

Three outcomes, and they must stay distinct. `:unreachable` is offline or no origin.
`:empty` is a remote that answered and has nothing in it -- which is the NORMAL state of a
student's repository until their first push, so reporting it as unreachable would tell every
student on their first review that GitHub was down. `ls-remote` exits 0 with no output in
that case, so success and emptiness have to be read separately.
"""
function remote_head(work)
    # Bound the wait with git's own slow-transfer limits; macOS has no `timeout`.
    ok, out = git_try(work, "-c", "http.lowSpeedLimit=1000", "-c", "http.lowSpeedTime=5",
                      "ls-remote", "origin", "HEAD")
    ok || return :unreachable
    parts = split(out)
    isempty(parts) ? :empty : String(first(parts))
end

"Is `sha` an ancestor of, or equal to, `target`? Nothing when either is not known locally."
function reachable_from(work, sha, target)
    (sha === nothing || target === nothing) && return nothing
    git(work, "cat-file", "-e", target * "^{commit}") === nothing &&
        git(work, "rev-parse", "--verify", target * "^{commit}") === nothing && return nothing
    try
        cmd = pipeline(Cmd(`git merge-base --is-ancestor $sha $target`; dir = work),
                       stderr = devnull)
        run(cmd)
        return true
    catch
        return false
    end
end

"The sha of the last commit that touched `path`, or nothing if it was never committed."
last_commit_for(work, path) = git(work, "log", "-1", "--format=%H", "--", path)

"""
Files the student has produced that the course actually collects.

Paths are built with a FORWARD SLASH, not `joinpath`. These strings are compared against
the output of `git diff --name-only`, and git emits forward slashes on every platform. On
Windows `joinpath` would produce `reviews\\1-intr-3.md`, which matches nothing in that set,
so the "you have edited this since that commit" note would never fire -- the exact
confident-but-wrong "we can see this" the porcelain comment below was written to prevent.
Found on Windows 2026-08-21; `test_check_submitted.jl` asserts the forward-slash form.
"""
function collected_files(work)
    found = String[]
    revdir = joinpath(work, "reviews")
    if isdir(revdir)
        for f in sort(readdir(revdir))
            endswith(f, ".md") && push!(found, "reviews/" * f)
        end
    end
    isfile(joinpath(work, "activity-log.jsonl")) && push!(found, "activity-log.jsonl")
    return found
end

function main()
    work = find_work_dir()
    if work === nothing
        println("No work repository found. Run this from inside your ISE754 folder.")
        return 0
    end

    files = collected_files(work)
    if isempty(files)
        println("Nothing to submit yet: no reviews and no activity log in work/.")
        println("Run a review first, for example  /review 1.3")
        return 0
    end

    println("ISE 754 -- can the teaching staff see your work?")
    println()

    rhead = remote_head(work)
    reachable = rhead !== :unreachable
    # Files edited since the last commit. Deliberately NOT `git status --porcelain`:
    # its first two columns are significant whitespace, and stripping the output -- which
    # any general-purpose helper does -- eats the leading space of " M path" and shifts
    # every fixed-column parse by one. That produced the worst possible bug in this tool,
    # a confident "we can see this" while the student had unsaved edits. `diff --name-only`
    # emits bare paths with no columns to misread.
    dirty_raw = git(work, "diff", "--name-only", "HEAD")
    dirty_set = dirty_raw === nothing ? String[] :
                [String(strip(l)) for l in split(dirty_raw, '\n') if !isempty(strip(l))]

    all_there = true
    for f in files
        commit = last_commit_for(work, f)
        print("  ", f, "\n")
        if commit === nothing
            println("      committed : NO")
            println("      on GitHub : NO  <-- we cannot see this")
            all_there = false
        else
            println("      committed : yes (", first(commit, 7), ")")
            if rhead === :unreachable
                println("      on GitHub : could not reach GitHub, so this is unconfirmed")
                all_there = false
            elseif rhead === :empty
                println("      on GitHub : NO  <-- we cannot see this")
                all_there = false
            else
                on = reachable_from(work, commit, rhead)
                if on === true
                    println("      on GitHub : YES  <-- we can see this")
                elseif on === false
                    println("      on GitHub : NO  <-- we cannot see this")
                    all_there = false
                else
                    println("      on GitHub : unconfirmed; run `git pull --no-rebase` first")
                    all_there = false
                end
            end
        end
        if f in dirty_set
            println("      note      : you have edited this since that commit, so the")
            println("                  version we can see is the older one")
            all_there = false
        end
    end

    println()
    if !reachable
        println("Could not reach GitHub. You may be offline, or `origin` may not be set.")
        println("Nothing above is confirmed. Try again when you are online.")
    elseif all_there
        println("Everything above is on GitHub. It is submitted and we can see it.")
    else
        println("Something above is NOT submitted. From your ISE754/work folder:")
        println("    git add -A")
        println("    git commit -m \"review\"")
        println("    git push")
        println("Then run this check again.")
    end
    return 0
end

exit(main())
