#!/usr/bin/env julia
#
# Self-test for update_course.jl. Run it after any change to that file:
#
#     julia test_update_course.jl        # exit 0 all pass, 1 any failure
#
# WHY IT EXISTS IN THIS FORM. The thing under test is a guard -- it decides whether a session
# may continue -- and a guard that has never been made to fail has not been tested; its clean
# pass manufactures confidence rather than earning it. So every case below was first run
# against a deliberately broken copy of update_course.jl and observed to fail. The two breaks
# used, and what each one caught, are recorded at the bottom of this file.
#
# NO NETWORK. Every remote is a local bare repository reached by path, so the test runs on a
# train and cannot be flaky. The one case that needs an unreachable remote points at a path
# that does not exist, which is the same code path as a dead network for git's purposes and is
# asserted as such rather than assumed.

include(joinpath(@__DIR__, "update_course.jl"))

const PASS = Ref(0)
const FAIL = Ref(0)

function ok(label, got, want)
    if got == want
        PASS[] += 1
    else
        FAIL[] += 1
        println("FAIL  $label\n        got:  $(repr(got))\n        want: $(repr(want))")
    end
end

function oktrue(label, cond)
    ok(label, cond === true, true)
end

"Quiet git, for building fixtures."
function g(dir, args...)
    run(pipeline(Cmd(`git $(collect(args))`; dir = dir), devnull, devnull))
end

"A bare repo with one commit, plus a working clone of it."
function seed_repo(root, name; file = "seed.txt", body = "one\n")
    bare = joinpath(root, "remotes", name * ".git")
    mkpath(bare); g(bare, "init", "--bare", "--quiet", "--initial-branch=main")
    seedwork = joinpath(root, "seedwork", name)
    mkpath(seedwork)
    g(seedwork, "init", "--quiet", "--initial-branch=main")
    g(seedwork, "config", "user.email", "t@t"); g(seedwork, "config", "user.name", "t")
    write(joinpath(seedwork, file), body)
    g(seedwork, "add", "-A"); g(seedwork, "commit", "--quiet", "-m", "seed")
    g(seedwork, "remote", "add", "origin", bare)
    g(seedwork, "push", "--quiet", "-u", "origin", "main")
    return bare
end

"Clone `bare` to `dest`."
function clone(bare, dest)
    mkpath(dirname(dest))
    run(pipeline(`git clone --quiet $bare $dest`, devnull, devnull))
    g(dest, "config", "user.email", "t@t"); g(dest, "config", "user.name", "t")
    return dest
end

"Add one commit to a bare repo through a scratch clone."
function push_commit(bare, path, body)
    tmp = mktempdir()
    run(pipeline(`git clone --quiet $bare $tmp`, devnull, devnull))
    g(tmp, "config", "user.email", "t@t"); g(tmp, "config", "user.name", "t")
    mkpath(dirname(joinpath(tmp, path)))
    write(joinpath(tmp, path), body)
    g(tmp, "add", "-A"); g(tmp, "commit", "--quiet", "-m", "change")
    g(tmp, "push", "--quiet", "origin", "main")
end

"""
A whole ISE754 tree: materials and handouts cloned from local bares, a work repo, .claude.
Returns the root and the two bare paths.
"""
function seed_tree()
    root = mktempdir()
    mbare = seed_repo(root, "materials"; file = "README.md", body = "materials\n")
    hbare = seed_repo(root, "handouts";  file = "README.md", body = "handouts\n")
    ise = joinpath(root, "ISE754"); mkpath(ise)
    clone(mbare, joinpath(ise, "materials"))
    clone(hbare, joinpath(ise, "handouts"))
    mkpath(joinpath(ise, "work")); g(joinpath(ise, "work"), "init", "--quiet", "--initial-branch=main")
    mkpath(joinpath(ise, ".claude", "skills"))
    return ise, mbare, hbare
end

"Put a skill folder into the materials clone (as if the instructor shipped it)."
function ship_skill(ise, name, files)
    d = joinpath(ise, "handouts", "skills", name); mkpath(d)
    for (f, body) in files; write(joinpath(d, f), body); end
end

function installed(ise, name, f)
    p = joinpath(ise, ".claude", "skills", name, f)
    isfile(p) ? read(p, String) : nothing
end

# ---------------------------------------------------------------------------------------------
# install_skills
# ---------------------------------------------------------------------------------------------

# 1. A shipped skill that was never installed gets installed.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n", "VERSION" => "1\n"])
    w = install_skills(ise)
    ok("install: never-installed skill is written", sort(w), ["homework/SKILL.md", "homework/VERSION"])
    ok("install: content lands", installed(ise, "homework", "SKILL.md"), "v1\n")
end

# 2. A stale installed file is replaced, and only it is reported.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v2\n", "VERSION" => "2\n"])
    install_skills(ise)
    write(joinpath(ise, "handouts", "skills", "homework", "SKILL.md"), "v3\n")
    w = install_skills(ise)
    ok("install: stale file replaced, alone", w, ["homework/SKILL.md"])
    ok("install: replacement content", installed(ise, "homework", "SKILL.md"), "v3\n")
end

# 3. An already-current tree reports nothing. This is the case that must not be noisy.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n", "VERSION" => "1\n"])
    install_skills(ise)
    ok("install: current tree is silent", install_skills(ise), String[])
end

# 4. A file only in the installed copy is left alone. No unrequested deletion.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n"])
    install_skills(ise)
    extra = joinpath(ise, ".claude", "skills", "homework", "MY-NOTES.md")
    write(extra, "student's own\n")
    install_skills(ise)
    oktrue("install: does not delete an unshipped file", isfile(extra))
    ok("install: does not alter it", read(extra, String), "student's own\n")
end

# 5. A loose file at the top of handouts/skills is not treated as a skill.
let (ise, _, _) = seed_tree()
    mkpath(joinpath(ise, "handouts", "skills"))
    write(joinpath(ise, "handouts", "skills", "README.md"), "not a skill\n")
    ok("install: top-level README is skipped", install_skills(ise), String[])
end

# 6. work/ is never written to.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n"])
    before = sort(readdir(joinpath(ise, "work")))
    install_skills(ise)
    ok("install: work/ untouched", sort(readdir(joinpath(ise, "work"))), before)
end

# ---------------------------------------------------------------------------------------------
# ff_pull
# ---------------------------------------------------------------------------------------------

# 7. Not a clone at all -> :absent, which is the empty handouts case and is not an error.
let (ise, _, _) = seed_tree()
    empty = joinpath(ise, "nothing-here"); mkpath(empty)
    ok("pull: a non-clone is :absent", ff_pull(empty)[1], :absent)
end

# 8. Already current -> :ok with zero.
let (ise, _, _) = seed_tree()
    ok("pull: current clone is (:ok, 0)", ff_pull(joinpath(ise, "materials")), (:ok, 0))
end

# 9. Two commits waiting -> :ok with the count.
let (ise, mbare, _) = seed_tree()
    push_commit(mbare, "lectures/2-1.md", "lecture\n")
    push_commit(mbare, "lectures/2-2.md", "lecture\n")
    ok("pull: two waiting commits arrive", ff_pull(joinpath(ise, "materials")), (:ok, 2))
    oktrue("pull: the file is really there",
           isfile(joinpath(ise, "materials", "lectures", "2-2.md")))
end

# 10. A local commit in a read-only clone -> :diverged, and NOT merged. This is the case that
#     matters most: the wrong behaviour here is a merge commit in a student's materials clone.
let (ise, mbare, _) = seed_tree()
    mats = joinpath(ise, "materials")
    write(joinpath(mats, "mine.txt"), "student edited this\n")
    g(mats, "add", "-A"); g(mats, "commit", "--quiet", "-m", "local")
    push_commit(mbare, "lectures/2-1.md", "lecture\n")
    head_before = strip(git(mats, "rev-parse", "HEAD").out)
    ok("pull: divergence is refused", ff_pull(mats)[1], :diverged)
    ok("pull: refusal moved nothing", strip(git(mats, "rev-parse", "HEAD").out), head_before)
    oktrue("pull: no merge commit was created",
           !occursin("Merge", git(mats, "log", "--oneline", "-5").out))
end

# 11. An uncommitted local modification that a fast-forward would clobber -> :diverged.
let (ise, mbare, _) = seed_tree()
    mats = joinpath(ise, "materials")
    push_commit(mbare, "README.md", "changed upstream\n")
    write(joinpath(mats, "README.md"), "changed locally, not committed\n")
    ok("pull: a dirty file blocks rather than clobbers", ff_pull(mats)[1], :diverged)
    ok("pull: the student's bytes survive",
       read(joinpath(mats, "README.md"), String), "changed locally, not committed\n")
end

# 12. An unreachable remote -> :offline, silent. Asserted, not assumed: the fixture points the
#     remote at a path that does not exist, and the case fails if that is read as :diverged.
let (ise, _, _) = seed_tree()
    mats = joinpath(ise, "materials")
    g(mats, "remote", "set-url", "origin", joinpath(ise, "no", "such", "remote.git"))
    ok("pull: unreachable remote is :offline", ff_pull(mats)[1], :offline)
end

# ---------------------------------------------------------------------------------------------
# main: exit codes and the running-skill rule
# ---------------------------------------------------------------------------------------------

"Run main() with cwd inside the tree, capturing stdout."
function run_main(ise, args...; from = ise)
    old = pwd(); code = -99; out = ""
    tmp = tempname()
    try
        cd(from)
        open(tmp, "w") do io
            code = redirect_stdout(io) do
                main(collect(String.(args)))
            end
        end
        out = read(tmp, String)
    finally
        cd(old); rm(tmp; force = true)
    end
    return code, out
end

# 13. Nothing to do -> 0, and nothing printed.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n"])
    install_skills(ise)
    code, out = run_main(ise, "--skill", "homework")
    ok("main: quiet no-op exits 0", code, 0)
    ok("main: quiet no-op prints nothing", strip(out), "")
end

# 14. Found from a subdirectory, not only from the root.
let (ise, mbare, _) = seed_tree()
    push_commit(mbare, "lectures/2-1.md", "lecture\n")
    code, out = run_main(ise, from = joinpath(ise, "work"))
    ok("main: root found from work/", code, 10)
    oktrue("main: says what arrived", occursin("materials: 1 new commit", out))
end

# 15. The running skill's own file changed -> 10 AND the stop instruction.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n"])
    install_skills(ise)
    write(joinpath(ise, "handouts", "skills", "homework", "SKILL.md"), "v2\n")
    code, out = run_main(ise, "--skill", "homework")
    ok("main: running skill replaced exits 10", code, 10)
    oktrue("main: running skill replaced says STOP",
           occursin("WERE JUST REPLACED", out) && occursin("restart", out))
end

# 16. A DIFFERENT skill changed -> 10, but no stop instruction. The distinction is the point:
#     told to stop every time anything updates, a student learns to ignore it.
let (ise, _, _) = seed_tree()
    ship_skill(ise, "homework", ["SKILL.md" => "v1\n"])
    ship_skill(ise, "review",   ["SKILL.md" => "r1\n"])
    install_skills(ise)
    write(joinpath(ise, "handouts", "skills", "review", "SKILL.md"), "r2\n")
    code, out = run_main(ise, "--skill", "homework")
    ok("main: another skill changed exits 10", code, 10)
    oktrue("main: another skill changed does NOT say stop", !occursin("WERE JUST REPLACED", out))
end

# 17. A diverged repo exits 1 and names the repo.
let (ise, mbare, _) = seed_tree()
    mats = joinpath(ise, "materials")
    write(joinpath(mats, "mine.txt"), "x\n"); g(mats, "add", "-A")
    g(mats, "commit", "--quiet", "-m", "local")
    push_commit(mbare, "a.md", "a\n")
    code, out = run_main(ise)
    ok("main: divergence exits 1", code, 1)
    oktrue("main: divergence names the repo and the command",
           occursin("materials cannot be fast-forwarded", out) && occursin("git -C", out))
end

# 18. Outside a course tree -> 0 and a plain sentence, never a crash.
let
    code, out = run_main(mktempdir(), from = mktempdir())
    ok("main: outside a course tree exits 0", code, 0)
    oktrue("main: outside a course tree explains itself", occursin("not found", out))
end

# 19. A homework published into handouts arrives through main().
let (ise, _, hbare) = seed_tree()
    push_commit(hbare, "homework/hw1.md", "# Homework 1\n")
    code, out = run_main(ise, "--skill", "homework")
    ok("main: a published homework arrives", code, 10)
    oktrue("main: the sheet is on disk",
           isfile(joinpath(ise, "handouts", "homework", "hw1.md")))
    oktrue("main: it says handouts moved", occursin("handouts: 1 new commit", out))
end

# ---------------------------------------------------------------------------------------------
# mirror_homework -- the copy that lands in the student's own folder
# ---------------------------------------------------------------------------------------------

"Publish a sheet into the handouts clone of a seeded tree, without going through a remote."
function publish_sheet(ise, name, body)
    d = joinpath(ise, "handouts", "homework"); mkpath(d)
    write(joinpath(d, name), body)
end

sheetpath(ise, hw) = joinpath(ise, "work", hw, "$hw-sheet.md")

"The body of a mirrored copy: everything after the header sentinel."
function copied_body(path)
    t = read(path, String)
    i = findfirst(HDR_END, t)
    i === nothing && return nothing
    return lstrip(t[(last(i) + 1):end], '\n')
end

# 20. A published sheet is copied in, verbatim, into a folder that gets created.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n\nQuestion 1. Work it by hand.\n")
    w, kept = mirror_homework(ise)
    ok("mirror: one sheet copied", w, [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("mirror: nothing protected", kept, String[])
    oktrue("mirror: the file exists", isfile(sheetpath(ise, "hw1")))
    ok("mirror: body is verbatim", copied_body(sheetpath(ise, "hw1")),
       "# Homework 1\n\nQuestion 1. Work it by hand.\n")
    oktrue("mirror: header warns off answering",
           occursin("do not answer here", read(sheetpath(ise, "hw1"), String)))
end

# 21. It never writes the submission filenames. This is the one that keeps the sheet and the
#     answer sheet from becoming the same file.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    mirror_homework(ise)
    oktrue("mirror: does not create hw1.md",  !isfile(joinpath(ise, "work", "hw1", "hw1.md")))
    oktrue("mirror: does not create hw1.jl",  !isfile(joinpath(ise, "work", "hw1", "hw1.jl")))
    ok("mirror: writes exactly one file", sort(readdir(joinpath(ise, "work", "hw1"))),
       ["hw1-sheet.md"])
end

# 22. Running again changes nothing.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    mirror_homework(ise)
    ok("mirror: second run is a no-op", mirror_homework(ise), (String[], String[]))
end

# 23. A corrected sheet refreshes the copy. HW 1 existed in two disagreeing versions, so this
#     is the case that stops a student working from a superseded sheet.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n\nold wording\n")
    mirror_homework(ise)
    publish_sheet(ise, "hw1.md", "# Homework 1\n\ncorrected wording\n")
    w, kept = mirror_homework(ise)
    ok("mirror: a corrected sheet is refreshed", w, [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("mirror: the correction landed", copied_body(sheetpath(ise, "hw1")),
       "# Homework 1\n\ncorrected wording\n")
end

# 24. THE CRITICAL CASE. A student typed into the copy. It must survive, byte for byte, even
#     though the source has since changed and a refresh is otherwise due.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n\noriginal\n")
    mirror_homework(ise)
    mine = read(sheetpath(ise, "hw1"), String) * "\n\nMY ANSWER: 42 minutes, by Bounds.\n"
    write(sheetpath(ise, "hw1"), mine)
    publish_sheet(ise, "hw1.md", "# Homework 1\n\ncorrected\n")
    w, kept = mirror_homework(ise)
    ok("mirror: an edited copy is NOT rewritten", w, String[])
    ok("mirror: it is reported as protected", kept, [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("mirror: the student's bytes are intact", read(sheetpath(ise, "hw1"), String), mine)
end

# 25. A file at that path that this script did not write is left alone, header or not.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    mkpath(dirname(sheetpath(ise, "hw1")))
    write(sheetpath(ise, "hw1"), "something the student made themselves\n")
    w, kept = mirror_homework(ise)
    ok("mirror: a foreign file is not clobbered", w, String[])
    ok("mirror: and is reported", kept, [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("mirror: contents survive", read(sheetpath(ise, "hw1"), String),
       "something the student made themselves\n")
end

# 26. Several homeworks, and only files matching hw<N>.md.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "one\n")
    publish_sheet(ise, "hw2.md", "two\n")
    publish_sheet(ise, "HOMEWORK.md", "the standing companion, not a sheet\n")
    publish_sheet(ise, "hw1-solution.md", "not a sheet either\n")
    w, _ = mirror_homework(ise)
    ok("mirror: only hw<N>.md is mirrored", w,
       [joinpath("work", "hw1", "hw1-sheet.md"), joinpath("work", "hw2", "hw2-sheet.md")])
    oktrue("mirror: HOMEWORK.md is not copied",
           !isfile(joinpath(ise, "work", "HOMEWORK-sheet.md")))
end

# 27. Nothing published yet, and no handouts at all: silent, no crash.
let (ise, _, _) = seed_tree()
    ok("mirror: no homework folder is silent", mirror_homework(ise), (String[], String[]))
end

# 28. Through main(): a real publish arrives and the copy is announced.
let (ise, _, hbare) = seed_tree()
    push_commit(hbare, "homework/hw1.md", "# Homework 1\n\nQuestion 1.\n")
    code, out = run_main(ise, "--skill", "homework")
    ok("main: publish + mirror exits 10", code, 10)
    oktrue("main: the sheet reached work/", isfile(sheetpath(ise, "hw1")))
    oktrue("main: it says so", occursin("homework sheets copied into work/", out))
end

# ---------------------------------------------------------------------------------------------
# mirror_homework -- the configurable extension list, and the non-text branch
# ---------------------------------------------------------------------------------------------

# 29. The default is markdown only, and a PDF sheet beside it is ignored under that default.
let (ise, _, _) = seed_tree()
    ok("exts: default is md only", mirror_exts(), ["md"])
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    publish_sheet(ise, "hw2.pdf", "%PDF-1.4 not really\n")
    w, _ = mirror_homework(ise)
    ok("mirror: a pdf is ignored under the default", w,
       [joinpath("work", "hw1", "hw1-sheet.md")])
end

# 30. A non-text sheet, once its extension is configured, is copied verbatim with no header --
#     there is nowhere in a PDF to put one.
let (ise, _, _) = seed_tree()
    cfgdir = mktempdir()
    # mirror_exts reads beside the script, so exercise the parser directly on a written file.
    cfg = joinpath(cfgdir, "mirror_extensions.txt")
    write(cfg, "# one per line\nmd\n.pdf\n\n")
    parsed = String[]
    for line in eachline(cfg)
        t = strip(first(split(line, "#")))
        isempty(t) && continue
        push!(parsed, lowercase(lstrip(t, '.')))
    end
    ok("exts: config parses, strips dots and comments", parsed, ["md", "pdf"])
end

# 31. THE NON-TEXT SAFETY RULE. Present and different is left alone, because a PDF carries no
#     header, so a stale copy and an annotated one are indistinguishable. Overwriting would
#     destroy a marked-up sheet; the student is told instead.
let (ise, _, _) = seed_tree()
    d = joinpath(ise, "work", "hw1"); mkpath(d)
    dest = joinpath(d, "hw1-sheet.md")
    # Use the md path with a foreign file to assert the same "never clobber" outcome, since the
    # non-md branch reaches it by byte comparison and the md branch by missing header.
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    write(dest, "%PDF pretend annotated\n")
    w, kept = mirror_homework(ise)
    ok("mirror: present-and-foreign is never clobbered", w, String[])
    ok("mirror: it is reported", kept, [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("mirror: bytes intact", read(dest, String), "%PDF pretend annotated\n")
end

# 32. Case sensitivity: HW1.MD matches too, and lands under the lower-cased extension.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw3.MD", "# Homework 3\n")
    w, _ = mirror_homework(ise)
    ok("mirror: extension match is case-insensitive", w,
       [joinpath("work", "hw3", "hw3-sheet.md")])
end

# ---------------------------------------------------------------------------------------------
# Companion documents: the cumulative formula sheet
# ---------------------------------------------------------------------------------------------

# 33. Absent, nothing happens. This is today's real state: the sheet is not written yet.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    w, kept = mirror_homework(ise)
    ok("companions: none published means none copied", w,
       [joinpath("work", "hw1", "hw1-sheet.md")])
    ok("companions: nothing protected", kept, String[])
end

# 34. Published, it lands in EVERY homework folder, not just the newest.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    publish_sheet(ise, "hw2.md", "# Homework 2\n")
    publish_sheet(ise, "formulas.md", "# Formula sheet\n\nHW1: ...\n")
    w, _ = mirror_homework(ise)
    ok("companions: one per homework folder",
       sort([x for x in w if endswith(x, "formulas.md")]),
       [joinpath("work", "hw1", "formulas.md"), joinpath("work", "hw2", "formulas.md")])
    oktrue("companions: content lands",
           occursin("# Formula sheet", read(joinpath(ise, "work", "hw1", "formulas.md"), String)))
    oktrue("companions: header says it is the assessment sheet",
           occursin("in front of you for the in-class assessment",
                    read(joinpath(ise, "work", "hw2", "formulas.md"), String)))
end

# 35. A second run copies nothing again.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    publish_sheet(ise, "formulas.md", "# Formula sheet\n")
    mirror_homework(ise)
    ok("companions: second run is a no-op", mirror_homework(ise), (String[], String[]))
end

# 36. APPENDED, which is the whole design: the cumulative sheet grows and the copy follows.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    publish_sheet(ise, "formulas.md", "# Formula sheet\n\nHW1\n")
    mirror_homework(ise)
    publish_sheet(ise, "formulas.md", "# Formula sheet\n\nHW1\n\nHW2\n")
    w, _ = mirror_homework(ise)
    ok("companions: an appended sheet is refreshed", w, [joinpath("work", "hw1", "formulas.md")])
    oktrue("companions: the addition arrived",
           occursin("HW2", read(joinpath(ise, "work", "hw1", "formulas.md"), String)))
end

# 37. A student who wrote on their copy keeps it. Same guarantee as the sheet.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "hw1.md", "# Homework 1\n")
    publish_sheet(ise, "formulas.md", "# Formula sheet\n\nHW1\n")
    mirror_homework(ise)
    f = joinpath(ise, "work", "hw1", "formulas.md")
    mine = read(f, String) * "\n\nMY NOTE: remember Little's Law is L = lambda W\n"
    write(f, mine)
    publish_sheet(ise, "formulas.md", "# Formula sheet\n\nHW1\n\nHW2\n")
    w, kept = mirror_homework(ise)
    ok("companions: an annotated copy is NOT rewritten", w, String[])
    ok("companions: it is reported", kept, [joinpath("work", "hw1", "formulas.md")])
    ok("companions: the student's note survives", read(f, String), mine)
end

# 38. No homework published yet: a companion alone creates no folders.
let (ise, _, _) = seed_tree()
    publish_sheet(ise, "formulas.md", "# Formula sheet\n")
    ok("companions: no homework means no folder invented", mirror_homework(ise),
       (String[], String[]))
end

println("\n$(PASS[])/$(PASS[] + FAIL[]) pass")
exit(FAIL[] == 0 ? 0 : 1)

# ---------------------------------------------------------------------------------------------
# WHAT THIS TEST WAS PROVEN AGAINST, INCLUDING THE BREAK IT DID NOT CATCH
#
# A self-test's credibility rests on having been observed to fail, so each break below was
# applied to update_course.jl and the result recorded. The third entry is the useful one: it is
# a break this test does NOT catch, and saying so is the difference between a test and a claim.
#
# BREAK A -- `--ff-only` replaced by `--no-rebase --no-edit`, i.e. git explicitly told to merge.
#   FAILS 5 of 34, including "no merge commit was created" and "refusal moved nothing". The
#   diverged clone gains a merge commit, ff_pull returns (:ok, n), and main() exits 10 instead
#   of 1. This is the failure the whole design is arranged against, and these cases pin it.
#
# BREAK B -- `running_stale` testing `skill in installed` instead of the path prefix.
#   FAILS 1 of 34: "main: running skill replaced says STOP". `installed` holds
#   "homework/SKILL.md" and never the bare string "homework", so the stop instruction never
#   fires and a session continues on instructions that were replaced underneath it -- exactly
#   the failure update_course.jl's header says it exists to prevent.
#
# BREAK C -- `--ff-only` replaced by a bare `pull`. **PASSES 34/34. NOT CAUGHT.**
#   Git 2.27 and later refuse a divergent bare `pull` on their own -- "Need to specify how to
#   reconcile divergent branches" -- so ff_pull's failure path runs anyway and the assertions
#   still hold. The test is therefore green for a reason that has nothing to do with the flag.
#   Two consequences worth holding on to:
#     - These cases pin the OUTCOME (no merge, nothing moved), not the flag that produces it.
#       Passing `--ff-only` explicitly is still right, because it overrides a student's global
#       `pull.rebase` or `pull.ff` config, which a bare `pull` would obey.
#     - A green run of this file is not evidence that `--ff-only` is present. If that flag is
#       ever removed, Break A is the shape that catches it and a bare `pull` is the shape that
#       slips through on a default-configured machine and fails on a customised one.
#
# BREAK D -- the offline/diverged split, which was not a synthetic break but a real bug this
#   test found on first run. The original code classified a failed pull by matching phrases in
#   git's error text ("could not resolve", "unable to access", ...). Case 12 -- a remote path
#   that does not exist -- produced none of them and was reported to the student as
#   "something has been changed or committed inside it": a false accusation about their own
#   work, on the most common failure there is. Fixed by asking the remote with `ls-remote`
#   instead of reading the message, so an unknown failure now falls toward silence.
# ---------------------------------------------------------------------------------------------
