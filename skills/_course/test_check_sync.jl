#!/usr/bin/env julia
#
# Regression test for check_sync.jl.
#
# WHAT THIS PROTECTS. The hook runs at the start of EVERY session, including sessions with
# nothing to do with the course. Two properties matter more than any individual message:
#
#   1. IT IS SILENT WHEN THERE IS NOTHING TO SAY. A hook that greets every session teaches
#      people to ignore it, and it would be ignored precisely when it finally mattered. Most
#      of the cases below assert NO output.
#   2. IT ALWAYS EXITS 0. It is a reporter, not a gate. A nonzero exit from a SessionStart
#      hook is a course-wide outage, and no message is worth that.
#
# Everything runs against local bare repositories in a temp directory. No network. The
# materials-remote case uses a local bare repo as `origin`, which `git ls-remote` handles
# exactly as it handles a URL, so the network path is exercised without a network.
#
# Run:  julia skills/_course/test_check_sync.jl
# Exit: 0 all passed · 1 any failure

const HOOK = joinpath(@__DIR__, "check_sync.jl")

passed = 0
failed = 0

function check(name, cond)
    global passed, failed
    if cond
        passed += 1
        println("PASS  ", name)
    else
        failed += 1
        println("FAIL  ", name)
    end
end

"Run the hook with `dir` as cwd. Returns (stdout, exitcode)."
function run_hook(dir)
    out = IOBuffer()
    p = run(pipeline(Cmd(`julia $HOOK`; dir = dir), stdout = out, stderr = devnull); wait = false)
    wait(p)
    return (String(take!(out)), p.exitcode)
end

git(dir, args...) = run(pipeline(Cmd(`git $args`; dir = dir), stdout = devnull, stderr = devnull))

"""
Build a student tree: ISE754/{materials,work,.claude/skills}, each wired to a local bare repo.
`skills` seeds one skill folder in materials and installs it, so the default tree is CLEAN.
"""
function build(root; with_skills = true)
    mkpath(root)
    for name in ("materials", "work")
        bare = joinpath(root, "$name.git")
        mkpath(bare)
        git(bare, "init", "--bare", "-q", "--initial-branch=main")
        git(root, "clone", "-q", bare, name)
        d = joinpath(root, name)
        git(d, "config", "user.email", "t@t")
        git(d, "config", "user.name", "t")
        write(joinpath(d, "seed.txt"), "seed\n")
        git(d, "add", "-A"); git(d, "commit", "-qm", "seed"); git(d, "push", "-q", "origin", "main")
    end
    if with_skills
        sk = joinpath(root, "materials", "skills", "review")
        mkpath(sk)
        write(joinpath(sk, "SKILL.md"), "# review\nversion 1\n")
        m = joinpath(root, "materials")
        git(m, "add", "-A"); git(m, "commit", "-qm", "skill"); git(m, "push", "-q", "origin", "main")
        inst = joinpath(root, ".claude", "skills", "review")
        mkpath(inst)
        cp(joinpath(sk, "SKILL.md"), joinpath(inst, "SKILL.md"); force = true)
    end
    return root
end

"Push a new commit to a repo's bare origin from a second clone, leaving `root`'s clone behind."
function advance_remote(root, name; skills = false)
    tmp = mktempdir()
    git(tmp, "clone", "-q", joinpath(root, "$name.git"), "c")
    c = joinpath(tmp, "c")
    git(c, "config", "user.email", "t@t"); git(c, "config", "user.name", "t")
    if skills
        d = joinpath(c, "skills", "review"); mkpath(d)
        write(joinpath(d, "SKILL.md"), "# review\nversion 2\n")
    else
        write(joinpath(c, "new.txt"), "new\n")
    end
    git(c, "add", "-A"); git(c, "commit", "-qm", "advance"); git(c, "push", "-q", "origin", "main")
end

println("check_sync.jl regression test\n" * "="^62)

mktempdir() do tmp

    # ---- A. not near a work repository at all -------------------------------------------
    bare = joinpath(tmp, "nowhere"); mkpath(bare)
    out, code = run_hook(bare)
    check("A  no work repo: silent",            isempty(strip(out)))
    check("A  no work repo: exit 0",            code == 0)

    # ---- B. everything clean. THE FALSE-POSITIVE CASE, and the most important one --------
    r = build(joinpath(tmp, "clean"))
    out, code = run_hook(joinpath(r, "work"))
    check("B  clean tree: SILENT",              isempty(strip(out)))
    check("B  clean tree: exit 0",              code == 0)

    # ---- C. work behind: existing behaviour must survive ---------------------------------
    r = build(joinpath(tmp, "wbehind"))
    advance_remote(r, "work")
    git(joinpath(r, "work"), "fetch", "-q", "origin")
    out, code = run_hook(joinpath(r, "work"))
    # "NOT pulled" is asserted on purpose, and BOTH branches must use it. This case fetches
    # first, so @{u} is current and the offline comparison sees nothing -- yet work_behind()
    # asks the remote, returns true, and takes the remote-first branch. So the phrase has to
    # be identical in both, or this passes or fails depending on which mechanism noticed,
    # which is not a property worth testing. Dr. Kay found this as a 20/21 on 2026-08-21:
    # the remote-first branch said "does NOT have" and only the fallback still said
    # "NOT pulled". One vocabulary is worth more than precision about the mechanism.
    check("C  work behind: reported",           occursin("NOT pulled", out))
    check("C  work behind: exit 0",             code == 0)

    # ---- D. work ahead: existing behaviour must survive ----------------------------------
    r = build(joinpath(tmp, "wahead"))
    w = joinpath(r, "work")
    write(joinpath(w, "mine.txt"), "mine\n")
    git(w, "add", "-A"); git(w, "commit", "-qm", "mine")
    out, code = run_hook(w)
    check("D  work ahead: reported",            occursin("NOT been pushed", out))
    check("D  work ahead: exit 0",              code == 0)

    # ---- E. materials moved on the remote. THE NEW CASE ----------------------------------
    r = build(joinpath(tmp, "mbehind"))
    advance_remote(r, "materials")
    out, code = run_hook(joinpath(r, "work"))
    check("E  materials behind: reported",      occursin("materials", out) && occursin("git pull", out))
    check("E  materials behind: exit 0",        code == 0)
    check("E  materials behind: work silent",   !occursin("NOT pulled", out))

    # ---- F. installed skill differs from the shipped one ---------------------------------
    r = build(joinpath(tmp, "sdrift"))
    write(joinpath(r, ".claude", "skills", "review", "SKILL.md"), "# review\nOLD\n")
    out, code = run_hook(joinpath(r, "work"))
    check("F  skill drift: reported",           occursin("Step 7a", out))
    check("F  skill drift: exit 0",             code == 0)

    # ---- G. a shipped skill folder was never installed ------------------------------------
    r = build(joinpath(tmp, "smissing"))
    mkpath(joinpath(r, "materials", "skills", "homework"))
    write(joinpath(r, "materials", "skills", "homework", "SKILL.md"), "# homework\n")
    out, code = run_hook(joinpath(r, "work"))
    check("G  skill never installed: reported", occursin("Step 7a", out))

    # ---- H. the Step 7a trap: contents copied instead of the folder ------------------------
    r = build(joinpath(tmp, "flattened"))
    cp(joinpath(r, ".claude", "skills", "review", "SKILL.md"),
       joinpath(r, ".claude", "skills", "SKILL.md"); force = true)
    rm(joinpath(r, ".claude", "skills", "review"); recursive = true)
    out, code = run_hook(joinpath(r, "work"))
    check("H  flattened install: reported",     occursin("Step 7a", out))
    check("H  flattened install: exit 0",       code == 0)

    # ---- I. materials has no remote: must be silent, must not hang -------------------------
    r = build(joinpath(tmp, "noremote"))
    git(joinpath(r, "materials"), "remote", "remove", "origin")
    t0 = time()
    out, code = run_hook(joinpath(r, "work"))
    elapsed = time() - t0
    check("I  no materials remote: silent",     isempty(strip(out)))
    check("I  no materials remote: exit 0",     code == 0)
    check("I  no materials remote: under 20s",  elapsed < 20)

    # ---- J. no .claude/skills at all: a student mid-setup ----------------------------------
    r = build(joinpath(tmp, "noskills"); with_skills = false)
    out, code = run_hook(joinpath(r, "work"))
    check("J  no skills installed: silent",     isempty(strip(out)))
    check("J  no skills installed: exit 0",     code == 0)

end

println("="^62)
println("$passed passed, $failed failed")
failed > 0 && println("\nA FAIL on B, I or J is the serious kind: the hook has become noisy or\n" *
                      "it exits nonzero, and it runs at the start of every session.")
exit(failed == 0 ? 0 : 1)
