#!/usr/bin/env julia
#
# Regression test for note_error() deduplication in record_activity.jl.
#
# WHY THIS EXISTS. Measured 2026-08-24 on the first three real student sessions of the
# semester. Two of the three, bbreese and lsuleim, each carried NINE identical lines in
# activity-log.error:
#
#   1787585323  review block looks like the skill's template, not a session record ...
#   1787590896  review block looks like the skill's template, not a session record ...
#   ... seven more, 40 seconds to 8 minutes apart, ordinary turn spacing
#
# Both sessions SUCCEEDED. check_coverage reads 3 review sessions from 3 of 3 students, so
# every record landed and the nine lines described nothing wrong.
#
# The mechanism: Stop fires on every assistant turn, and before a session emits its real
# block the last ```course-log block in the transcript is the skill's own TEMPLATE. The
# template guard refuses it, correctly, and then said so once per turn.
#
# The cost is that collect_reviews.py appends "activity-log.error present" to any student
# holding this file, so on its first real use two students of three looked like mechanism
# failures and were not.
#
# WHAT MUST STAY TRUE. The guard's own signal. An abandoned session that only ever shows
# the template still has to leave exactly one line, and a genuinely different failure still
# has to append. Both are asserted below.
#
# RUN IT BOTH WAYS. This must FAIL on the undeduped note_error and PASS on the fixed one.
#
#   julia skills/_course/test_note_error_dedupe.jl

using Test

const SCRIPT = joinpath(@__DIR__, "record_activity.jl")
const ERRFILE = "activity-log.error"

"The skill's own template, verbatim in shape: worded timestamps, not real ones."
# This fixture must stay field-for-field identical to the template in review/SKILL.md.
# When patch 5 made not_understood and wants_covered required it was not updated, so the
# recorder rejected this block for a MISSING FIELD before it ever reached the template
# detection these tests are about, and two of them failed for a reason unrelated to what
# they test. Add every new required field here in the same commit that requires it.
const TEMPLATE_BLOCK = """```course-log
{
  "activity": "review",
  "lecture_id": "9.9",
  "started": "when the session began",
  "ended": "when it ended",
  "turns": 5,
  "questions": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "examples_verified": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""

function escaped_transcript(dir, block_inner, name = "transcript.jsonl")
    esc = replace(block_inner, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
    tr = joinpath(dir, name)
    write(tr, "{\"type\":\"assistant\",\"text\":\"$esc\"}\n")
    return tr
end

function run_hook(dir, tr)
    out = IOBuffer()
    base = Cmd(`julia $SCRIPT`; dir = dir)
    run(pipeline(base; stdin = IOBuffer("{\"transcript_path\": \"$tr\"}"), stdout = out))
    return String(take!(out))
end

errlines(work) = isfile(joinpath(work, ERRFILE)) ?
    filter(!isempty, strip.(readlines(joinpath(work, ERRFILE)))) : String[]

@testset "note_error does not repeat itself once per turn" begin

    @testset "nine turns against the template leave ONE line, not nine" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            tr = escaped_transcript(dir, TEMPLATE_BLOCK)
            for _ in 1:9
                run_hook(dir, tr)
            end
            lines = errlines(work)
            @test length(lines) == 1
            @test occursin("looks like the skill's template", lines[1])
        end
    end

    @testset "the guard's own signal survives: an abandoned session still leaves a line" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            tr = escaped_transcript(dir, TEMPLATE_BLOCK)
            run_hook(dir, tr)
            @test length(errlines(work)) == 1
        end
    end

    @testset "a DIFFERENT failure still appends rather than being swallowed" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            # First: the template complaint.
            run_hook(dir, escaped_transcript(dir, TEMPLATE_BLOCK, "t1.jsonl"))
            # Then a record missing a required field, which notes a different message.
            missing_field = """```course-log
{
  "activity": "review",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:10:00Z",
  "turns": 5
}
```"""
            run_hook(dir, escaped_transcript(dir, missing_field, "t2.jsonl"))
            lines = errlines(work)
            @test length(lines) == 2
            @test occursin("template", lines[1])
            @test occursin("missing field", lines[2])
        end
    end

    @testset "alternating failures are each recorded, not collapsed globally" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            missing_field = """```course-log
{
  "activity": "review",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:10:00Z",
  "turns": 5
}
```"""
            t1 = escaped_transcript(dir, TEMPLATE_BLOCK, "t1.jsonl")
            t2 = escaped_transcript(dir, missing_field, "t2.jsonl")
            run_hook(dir, t1); run_hook(dir, t1)   # collapses to one
            run_hook(dir, t2); run_hook(dir, t2)   # collapses to one
            run_hook(dir, t1)                      # differs from the last line, appends
            @test length(errlines(work)) == 3
        end
    end
end
