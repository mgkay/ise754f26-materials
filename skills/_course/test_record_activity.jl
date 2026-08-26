#!/usr/bin/env julia
#
# Regression test for record_activity.jl.
#
# WHY THIS EXISTS. On 2026-08-17 a full /review session ran, emitted a well-formed
# course-log block, and recorded nothing at all: no activity-log.jsonl, no
# activity-log.error, exit 0, no output. The hook was registered, Julia was on the
# path, and the block was correct. It failed because the transcript is JSON LINES,
# so the assistant's text arrives JSON-ESCAPED -- the block's newlines are the two
# characters \n and its quotes are \". Measured on the real transcript: the
# real-newline pattern matched 0 times, the escaped form matched 2.
#
# The failure was silent by construction. `block === nothing && return 0` is the
# deliberate path for a session that was not a course activity, so a broken parse and
# an ordinary session are indistinguishable, and the .error file is never reached.
#
# THE TEST THEREFORE FEEDS AN ESCAPED TRANSCRIPT, because that is the only kind that
# exists in production. An earlier hand-written plain-text fixture passed against the
# broken script and proved nothing -- it tested a format the harness never produces.
#
# RUN IT BOTH WAYS. This must FAIL on the unpatched script and PASS on the patched
# one. A test that has only ever passed has not been shown to detect anything.
#
#   julia skills/_course/test_record_activity.jl

using Test

const SCRIPT = joinpath(@__DIR__, "record_activity.jl")

"Write a transcript in the real format: one JSON line, assistant text escaped."
function escaped_transcript(dir, block_inner)
    esc = replace(block_inner, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
    tr = joinpath(dir, "transcript.jsonl")
    write(tr, "{\"type\":\"assistant\",\"text\":\"$esc\"}\n")
    return tr
end

function run_hook(dir, tr)
    out = IOBuffer()
    # `dir` must be set on the base Cmd BEFORE piping: Cmd(::CmdRedirect; dir=) has no
    # method, so setting it on the pipeline throws a MethodError rather than running.
    base = Cmd(`julia $SCRIPT`; dir = dir)
    run(pipeline(base; stdin = IOBuffer("{\"transcript_path\": \"$tr\"}"), stdout = out))
    return String(take!(out))
end

@testset "record_activity against a real JSON-Lines transcript" begin

    @testset "a complete record is written, and the push reminder is emitted" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "review",
  "lecture_id": "9.9",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:10:00Z",
  "turns": 5,
  "questions": [],
  "examples_verified": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""
            out = run_hook(dir, escaped_transcript(dir, block))
            log = joinpath(work, "activity-log.jsonl")

            @test isfile(log)                                     # THE regression
            @test occursin("\"lecture_id\": \"9.9\"", read(log, String))
            @test occursin("systemMessage", out)                  # the push reminder fires
            @test !isfile(joinpath(work, "activity-log.error"))
        end
    end

    @testset "a record missing a required field is refused BY NAME, not silently" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "review",
  "lecture_id": "9.9",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:10:00Z",
  "questions": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""
            run_hook(dir, escaped_transcript(dir, block))
            err = joinpath(work, "activity-log.error")

            # This assertion is what distinguishes a parse failure from a refusal.
            # Before the fix BOTH produced no log and no error, so the two were
            # indistinguishable and the diagnosis was impossible.
            @test isfile(err)
            @test occursin("examples_verified", read(err, String))
            @test !isfile(joinpath(work, "activity-log.jsonl"))
        end
    end

    # The three closing questions are the signal the next class meeting is planned from, and
    # the third is the only way a student can say the activity itself should change, so a
    # session that never asked them must not produce a record that looks complete. An EMPTY
    # list is a fine answer and is covered by the first testset above, which now carries [] for
    # both; these two cover the field being absent entirely, which means it was never asked.
    for field in ("not_understood", "wants_covered", "review_feedback")
        @testset "a review record with no $field is refused BY NAME" begin
            mktempdir() do dir
                work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
                lines = ["\"activity\": \"review\"",
                         "\"lecture_id\": \"9.9\"",
                         "\"started\": \"2026-01-01T00:00:00Z\"",
                         "\"ended\": \"2026-01-01T00:10:00Z\"",
                         "\"questions\": []",
                         "\"examples_verified\": []",
                         "\"not_understood\": []",
                         "\"wants_covered\": []",
                         "\"review_feedback\": []",
                         "\"big_idea_reached\": true",
                         "\"planted_error_caught\": true"]
                kept = filter(l -> !occursin("\"$field\"", l), lines)
                block = "```course-log\n{\n  " * join(kept, ",\n  ") * "\n}\n```"

                run_hook(dir, escaped_transcript(dir, block))
                err = joinpath(work, "activity-log.error")

                @test isfile(err)
                @test occursin(field, read(err, String))
                @test !isfile(joinpath(work, "activity-log.jsonl"))
            end
        end
    end

    # HOMEWORK. Added 2026-08-25 after the first dry run driven as a student. Before this,
    # PER_ACTIVITY named "review" and nothing else, so a homework record validated on the
    # shared three fields alone and whatever else the session had invented went in unchecked.
    # These three cases are what makes the schema real: a delivery records with the collecting
    # fields EMPTY, a submission records what the student named, and a session that never
    # collected them is refused by name rather than accepted as an empty one.

    @testset "a homework DELIVERY records, with the collecting fields empty" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "homework",
  "homework_id": "hw1",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:04:00Z",
  "questions": [],
  "checks_named": {}
}
```"""
            run_hook(dir, escaped_transcript(dir, block))
            log = joinpath(work, "activity-log.jsonl")

            # Empty is a fine answer. If this ever refuses, Step 2 of /homework can never see
            # a homework line after a delivery, and every later homework looks like the
            # student's first one.
            @test isfile(log)
            @test occursin("\"activity\": \"homework\"", read(log, String))
            @test !isfile(joinpath(work, "activity-log.error"))
        end
    end

    @testset "a homework SUBMISSION keeps the names the student actually wrote" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "homework",
  "homework_id": "hw1",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:20:00Z",
  "questions": ["do both checks have to be different from each other?"],
  "checks_named": {"1": ["Sanity"], "3": ["Bounds", "Units"]}
}
```"""
            run_hook(dir, escaped_transcript(dir, block))
            log = joinpath(work, "activity-log.jsonl")
            text = read(log, String)

            @test isfile(log)
            # "Sanity" is NOT one of the nine. /homework reports that to the student and the
            # record keeps what they said: correcting it here would destroy the measurement
            # the field exists to take.
            @test occursin("Sanity", text)
            @test occursin("Bounds", text)
            @test !isfile(joinpath(work, "activity-log.error"))
        end
    end

    @testset "a homework record with no checks_named is refused BY NAME" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "homework",
  "homework_id": "hw1",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:20:00Z",
  "questions": []
}
```"""
            run_hook(dir, escaped_transcript(dir, block))
            err = joinpath(work, "activity-log.error")

            @test isfile(err)
            @test occursin("checks_named", read(err, String))
            @test !isfile(joinpath(work, "activity-log.jsonl"))
        end
    end

    @testset "a session that was not a course activity stays silent" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            tr = joinpath(dir, "transcript.jsonl")
            write(tr, "{\"type\":\"assistant\",\"text\":\"here is some julia\\n\\n```julia\\n1+1\\n```\"}\n")
            out = run_hook(dir, tr)

            @test !isfile(joinpath(work, "activity-log.jsonl"))
            @test !isfile(joinpath(work, "activity-log.error"))
            @test isempty(strip(out))
        end
    end

    # ------------------------------------------------------------------------
    # Added 2026-08-20, from a real cold /review 1.3 run.
    #
    # The student said:  You've referred to a "Prior check" by name.
    #
    # The skill instructs that `questions` be recorded VERBATIM and calls it the
    # richest signal in the log, so a quote inside a student's own words is not an
    # exotic input, it is the expected one. The old unescape was three independent
    # `replace` passes, and a later pass cannot see where an earlier escape ended:
    # the transcript's four characters  \ \ \ "  came out as three,  \ \ "  -- a
    # literal backslash followed by a BARE quote, which closes the JSON string
    # early. The line was still written and still looked plausible to the eye, and
    # json.loads failed on it at column 279.
    #
    # Nothing in this suite caught that, because no fixture had ever put a quote
    # inside a value. Asserting a substring of the student's words would ALSO have
    # passed on the broken output -- the words survive, the escaping does not -- so
    # what is asserted here is the escaping itself.
    # ------------------------------------------------------------------------
    @testset "a quote in the student's own words survives as valid JSON" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "review",
  "lecture_id": "1.3",
  "started": "2026-08-20T15:27:41Z",
  "ended": "2026-08-20T15:52:03Z",
  "turns": 7,
  "questions": ["You've referred to a \\\"Prior check\\\" by name."],
  "examples_verified": [{"example": "Example 1", "check": "Bounds"}],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""
            out = run_hook(dir, escaped_transcript(dir, block))
            log = joinpath(work, "activity-log.jsonl")
            @test isfile(log)
            line = strip(read(log, String))

            # MUST be an escaped quote:            \"Prior check\"
            @test occursin("\\\"Prior check\\\"", line)
            # MUST NOT be backslash + bare quote:  \\"Prior check\\"
            @test !occursin("\\\\\"Prior check", line)
            # the push reminder still fires, and nothing was refused
            @test occursin("systemMessage", out)
            @test !isfile(joinpath(work, "activity-log.error"))
        end
    end

    # ------------------------------------------------------------------------
    # Added 2026-08-20, from a real /review 1.3 session that stopped after the
    # first question.
    #
    # last_block scans the WHOLE transcript, and the skill file is in it. Step 4
    # of SKILL.md shows a filled-in example inside a ```course-log fence, so a
    # session that never emits a real block still leaves exactly one block for
    # the hook to find: the template. It was recorded verbatim, "<ISO 8601>"
    # timestamps and all, with first_cut_correct, big_idea_reached and
    # planted_error_caught every one of them true.
    #
    # An abandoned session therefore produced a record indistinguishable from a
    # flawless one. That is worse than recording nothing: it is silent,
    # plausible, and wrong in the flattering direction, and it lands in the
    # dataset the instructor reads across twelve students all semester.
    #
    # The fixture is READ FROM SKILL.md rather than retyped, so this test cannot
    # drift away from the template it exists to reject.
    # ------------------------------------------------------------------------
    @testset "the skill's own template is never recorded as a session" begin
        skillmd = joinpath(@__DIR__, "..", "review", "SKILL.md")
        @test isfile(skillmd)
        text = read(skillmd, String)
        m = match(r"```course-log\s*\n(.*?)\n```"s, text)
        @test m !== nothing                       # the template is still in SKILL.md
        template = m.captures[1]
        @test occursin("<ISO 8601>", template)    # and still carries placeholders

        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = "```course-log\n" * template * "\n```"
            out = run_hook(dir, escaped_transcript(dir, block))

            @test !isfile(joinpath(work, "activity-log.jsonl"))   # THE regression
            err = joinpath(work, "activity-log.error")
            @test isfile(err)                                     # and it says why
            @test occursin("template", read(err, String))
            @test !occursin("systemMessage", out)                 # no false "recorded" nudge
        end
    end

    # ------------------------------------------------------------------------
    # Added 2026-08-21, from the first interactive dry run.
    #
    # Stop fires every time the assistant finishes a turn, and this hook reads
    # the LAST course-log block in the transcript. So once a session has emitted
    # its block, every later stop in that session finds the same block and
    # appends it again. One real review produced two byte-identical records
    # (sha 66943cfb4d9e) in a log that also held twelve template lines.
    #
    # Duplicates do not corrupt a record; they inflate the COUNT, in the
    # flattering direction, which is the hard kind to notice.
    # ------------------------------------------------------------------------
    @testset "the same session is not recorded twice" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            block = """```course-log
{
  "activity": "review",
  "lecture_id": "1.3",
  "started": "2026-08-21T02:28:53Z",
  "ended": "2026-08-21T02:41:00Z",
  "turns": 12,
  "questions": [],
  "examples_verified": [{"example": "Example 1", "check": "Bounds"}],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": false,
  "planted_error_caught": false
}
```"""
            tr = escaped_transcript(dir, block)
            log = joinpath(work, "activity-log.jsonl")

            run_hook(dir, tr)
            @test isfile(log)
            @test countlines(log) == 1

            run_hook(dir, tr)                      # a second Stop, same session
            @test countlines(log) == 1             # THE regression: still one

            run_hook(dir, tr)                      # and a third
            @test countlines(log) == 1
        end
    end

    @testset "a genuinely different session IS still recorded" begin
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            mk(ended) = """```course-log
{
  "activity": "review",
  "lecture_id": "1.3",
  "started": "2026-08-21T02:28:53Z",
  "ended": "$ended",
  "turns": 12,
  "questions": [],
  "examples_verified": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": false,
  "planted_error_caught": false
}
```"""
            log = joinpath(work, "activity-log.jsonl")
            run_hook(dir, escaped_transcript(dir, mk("2026-08-21T02:41:00Z")))
            run_hook(dir, escaped_transcript(dir, mk("2026-08-21T03:15:00Z")))
            @test countlines(log) == 2             # the guard must not over-suppress
        end
    end

    @testset "the last block wins when a template is quoted earlier in the session" begin
        # SKILL.md's own template is echoed into the transcript when the skill is read,
        # so a real session contains more than one fenced course-log block. The record
        # that counts is the one the session actually emitted, which is the last.
        mktempdir() do dir
            work = joinpath(dir, "work"); mkpath(joinpath(work, ".git"))
            tmpl = """```course-log
{
  "activity": "review",
  "lecture_id": "<lecture>",
  "started": "<ISO 8601>",
  "ended": "<ISO 8601>",
  "questions": [],
  "examples_verified": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""
            real = """```course-log
{
  "activity": "review",
  "lecture_id": "7.7",
  "started": "2026-01-01T00:00:00Z",
  "ended": "2026-01-01T00:10:00Z",
  "questions": [],
  "examples_verified": [],
  "not_understood": [],
  "wants_covered": [],
  "review_feedback": [],
  "big_idea_reached": true,
  "planted_error_caught": true
}
```"""
            run_hook(dir, escaped_transcript(dir, tmpl * "\n\nand later\n\n" * real))
            body = read(joinpath(work, "activity-log.jsonl"), String)

            @test occursin("\"lecture_id\": \"7.7\"", body)
            @test !occursin("<ISO 8601>", body)
        end
    end
end
