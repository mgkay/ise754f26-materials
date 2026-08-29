#!/usr/bin/env julia
# Self-test for build_profile.jl. Run: julia skills/_course/test_build_profile.jl
#
# The headline case is notes preservation. This script REWRITES a file that a student is invited
# to write in, so the way it fails worst is silently eating their writing. That case is asserted
# here rather than trusted, and it was made to fail before it was believed.

using Test
include(joinpath(@__DIR__, "build_profile.jl"))

REVIEW(lec, ended; nu = "[]", wc = "[]", rf = "[]", ex = "[]") =
    """{ "activity": "review", "lecture_id": "$lec", "started": "$(ended)T00:00:00Z", """ *
    """"ended": "$(ended)T00:10:00Z", "turns": 5, "questions": [], "not_understood": $nu, """ *
    """"wants_covered": $wc, "review_feedback": $rf, "examples_verified": $ex, """ *
    """"big_idea_reached": true, "planted_error_caught": true }"""

withwork(f, lines) = mktempdir() do d
    w = joinpath(d, "work"); mkpath(w)
    write(joinpath(w, "activity-log.jsonl"), isempty(lines) ? "" : join(lines, "\n") * "\n")
    f(w)
end

@testset "build_profile" begin

    @testset "only review sessions are read, and a bad line is skipped not fatal" begin
        withwork([REVIEW("1.3", "2026-08-20"),
                  """{ "activity": "homework", "homework_id": "hw1", "ended": "2026-08-21T00:00:00Z" }""",
                  "{ this is not json at all",
                  REVIEW("2.1", "2026-08-22")]) do w
            ss = sessions(joinpath(w, "activity-log.jsonl"))
            @test length(ss) == 2
            @test [s.lecture for s in ss] == ["1.3", "2.1"]
        end
    end

    @testset "a quote inside the student's own sentence survives" begin
        withwork([REVIEW("1.3", "2026-08-20";
                         nu = """["she said \\"use the geometric mean\\" and i did not follow"]""")]) do w
            ss = sessions(joinpath(w, "activity-log.jsonl"))
            @test length(ss) == 1
            @test occursin("\"use the geometric mean\"", ss[1].not_understood[1])
        end
    end

    @testset "non-ASCII in a verbatim answer survives" begin
        # Regression: the first version indexed a Char vector with String positions, which is
        # correct only while every character is ASCII. An em dash is where that broke.
        withwork([REVIEW("1.3", "2026-08-20"; nu = """["the ratio — i do not get it — at all"]""")]) do w
            ss = sessions(joinpath(w, "activity-log.jsonl"))
            @test ss[1].not_understood[1] == "the ratio — i do not get it — at all"
        end
    end

    @testset "checks and first-cut are read out of examples_verified" begin
        ex = """[ {"example": "Example 1", "check": "Bounds", "first_cut_correct": true, "verdict": "accept"},""" *
             """ {"example": "Example 3", "check": "Units", "first_cut_correct": false, "verdict": "reject"} ]"""
        withwork([REVIEW("1.3", "2026-08-20"; ex = ex)]) do w
            ss = sessions(joinpath(w, "activity-log.jsonl"))
            @test ss[1].checks == ["Bounds", "Units"]
            @test ss[1].first_cut == [true, false]
        end
    end

    @testset "THE STUDENT'S OWN NOTES SURVIVE A REBUILD" begin
        withwork([REVIEW("1.3", "2026-08-20")]) do w
            build(w)
            p = joinpath(w, "profile.md")
            txt = read(p, String)
            mine = "ask about circuity factors before the midterm. also my own worked example is in scratch.jl"
            write(p, replace(txt, "_Anything you write below this line is yours and is never overwritten._" => mine))

            # a second session lands, the file is rebuilt
            open(joinpath(w, "activity-log.jsonl"), "a") do io
                println(io, REVIEW("2.1", "2026-08-22"))
            end
            build(w)
            after = read(p, String)
            @test occursin(mine, after)              # their writing is still there
            @test occursin("2.1", after)             # and the derived half did update
        end
    end

    @testset "the derived half is replaced, not appended to" begin
        withwork([REVIEW("1.3", "2026-08-20")]) do w
            build(w); build(w); build(w)
            txt = read(joinpath(w, "profile.md"), String)
            @test length(collect(eachmatch(r"# What this course knows", txt))) == 1
            @test length(collect(eachmatch(Regex("^" * NOTES_HEAD * raw"\s*$", "m"), txt))) == 1
        end
    end

    @testset "two runs with no new session are byte-identical" begin
        withwork([REVIEW("1.3", "2026-08-20")]) do w
            build(w); a = read(joinpath(w, "profile.md"), String)
            build(w); b = read(joinpath(w, "profile.md"), String)
            @test a == b
        end
    end

    @testset "the carried list is capped and says how many are hidden" begin
        lines = [REVIEW("1.$i", "2026-08-0$(i%9+1)"; nu = """["open item number $i"]""") for i in 1:20]
        withwork(lines) do w
            build(w)
            txt = read(joinpath(w, "profile.md"), String)
            # Counted with a trailing newline, NOT as a bare substring: "open item number 1"
            # also occurs inside 10 through 19, which reported 14 shown when 12 were.
            shown = count(i -> occursin("open item number $i\n", txt), 1:20)
            @test shown == CARRIED_CAP
            @test occursin("$(20 - CARRIED_CAP) older item(s) not shown", txt)
            @test occursin("open item number 20", txt)   # the most recent is kept
            @test !occursin("open item number 1\n", txt)  # the oldest is not
        end
    end

    @testset "an empty log still produces a valid file with the student's section" begin
        withwork(String[]) do w
            build(w)
            txt = read(joinpath(w, "profile.md"), String)
            @test occursin("No reviews recorded yet", txt)
            @test occursin(NOTES_HEAD, txt)
        end
    end

    @testset "an absent log is not an error" begin
        mktempdir() do d
            w = joinpath(d, "work"); mkpath(w)
            @test isfile(build(w))
        end
    end
end
