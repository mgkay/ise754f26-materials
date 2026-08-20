#!/usr/bin/env julia
#
# Dry run for check_submitted.jl, against a local bare repository standing in for GitHub.
#
# WHY A LOCAL BARE REPO. The question the script answers is "does the REMOTE have this
# commit", and `git ls-remote` does not care whether the remote is GitHub or a directory.
# Using a bare repo exercises the real code path -- ls-remote, merge-base --is-ancestor --
# without pushing anything to anyone's account.
#
# WHAT THIS DOES NOT PROVE: that it behaves correctly against GitHub over HTTPS with NC
# State single sign-on in the way. That needs one run against a real student repository.
#
# RUN IT AND WATCH IT SAY NO. Every state below is asserted, including the three failure
# states, because a check that has only ever said YES has not been shown to detect anything.
#
#   julia skills/_course/test_check_submitted.jl

using Test

const SCRIPT = joinpath(@__DIR__, "check_submitted.jl")

run_check(work) = read(pipeline(Cmd(`julia $SCRIPT`; dir = work), stderr = devnull), String)

function git!(dir, args...)
    run(pipeline(Cmd(`git $(collect(args))`; dir = dir), stdout = devnull, stderr = devnull))
end

@testset "check_submitted tells the student the truth about the remote" begin
    mktempdir() do root
        bare = joinpath(root, "origin.git"); mkpath(bare)
        git!(root, "init", "--bare", "--initial-branch=main", bare)

        work = joinpath(root, "work"); mkpath(work)
        git!(root, "clone", "--quiet", bare, work)
        git!(work, "config", "user.email", "s@t"); git!(work, "config", "user.name", "student")
        mkpath(joinpath(work, "reviews"))

        @testset "an uncommitted review is reported as NOT submitted" begin
            write(joinpath(work, "reviews", "1-intr-3.md"), "# Review\n- predicted: 5ish\n")
            out = run_check(work)
            @test occursin("reviews/1-intr-3.md", out)
            @test occursin("committed : NO", out)
            @test occursin("NOT submitted", out)
            @test !occursin("we can see this", out)
        end

        @testset "committed but not pushed is still NOT submitted" begin
            git!(work, "add", "-A"); git!(work, "commit", "-m", "review 1.3")
            out = run_check(work)
            @test occursin("committed : yes", out)
            @test occursin("on GitHub : NO", out)      # the case the whole tool exists for
            @test occursin("NOT submitted", out)
        end

        @testset "after a push it says YES, and says it plainly" begin
            git!(work, "push", "--quiet", "-u", "origin", "main")
            out = run_check(work)
            @test occursin("on GitHub : YES", out)
            @test occursin("we can see this", out)
            @test occursin("It is submitted and we can see it.", out)
            @test !occursin("NOT submitted", out)
        end

        @testset "editing after the push warns that we hold the older version" begin
            write(joinpath(work, "reviews", "1-intr-3.md"), "# Review\n- predicted: 5ish\n- more\n")
            out = run_check(work)
            @test occursin("version we can see is the older one", out)
            @test occursin("NOT submitted", out)
        end

        @testset "an unreachable remote is reported as unconfirmed, never as YES" begin
            git!(work, "checkout", "--", "reviews/1-intr-3.md")
            git!(work, "remote", "set-url", "origin", joinpath(root, "no-such-repo.git"))
            out = run_check(work)
            @test occursin("Could not reach GitHub", out)
            @test !occursin("on GitHub : YES", out)
        end
    end
end
