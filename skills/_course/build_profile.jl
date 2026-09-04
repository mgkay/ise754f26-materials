#!/usr/bin/env julia
# build_profile.jl -- rewrite work/profile.md from work/activity-log.jsonl.
#
# WHAT THIS IS FOR. Dr. Kay, 2026-08-26: "each lecture is not a standalone island... it would
# remember, I remember like three lectures ago when we talked about circuity factors and now we
# need to use them, and I remember that you really were uncertain." The review agent reads one
# session at a time and forgets. This file is what it reads instead of the whole log.
#
# WHY REWRITTEN AND NEVER APPENDED. His constraint was 120 students and 25 lectures on an
# ordinary token budget. An appended file grows without bound and is the "big data store problem"
# he named; a rewritten summary is O(1) in the number of sessions, so the cost of reading it at
# session start does not change between week 2 and week 15. The log stays append-only and is
# never read in full by an agent.
#
# WHY VERBATIM AND NOT TAGGED. An earlier design tagged each item with a concept drawn from a
# controlled vocabulary, so the carried items could be matched mechanically to the lecture about
# to be taught. That needs a vocabulary nobody has written and a second required field. The
# student's own sentence, carried forward with the lecture it came from, is enough for an agent
# to judge relevance, and it keeps the verbatim rule the review already enforces. The concept map
# can be added later as enrichment; it is not a prerequisite.
#
# WHAT THE STUDENT OWNS. Everything under `## Your own notes` is copied through untouched on
# every rebuild. That section is the one part of this file a rebuild cannot destroy, and the
# preservation is asserted in the self-test rather than trusted, because losing a student's own
# writing to an automatic rewrite would be the worst failure this script can have.

# REVIEW ONLY, FOR NOW, AND THE ORDER IS THE SCHEDULE'S (Jake, 2026-08-28)
#
# Line ~160 filters to `activity == "review"` and skips everything else. That is deliberate
# and it is the right first step, because reviews are the only activity producing records
# today: two a week, every week, since 20 August.
#
# The other two arrive on dates, and the dates set the order:
#
#   homework   HW 1 is due 6:00 am Tue 8 September, so the first `homework` records land
#              then. record_activity already defines their shape: homework_id and
#              checks_named, which is which of the nine a student reached for per question.
#              That is the same signal this file already summarises for reviews, so covering
#              it is mostly widening the filter and giving the section a heading.
#
#   project    PROJ 1 is assigned Thu 10 September and due 6:00 am Tue 22 September. It is
#              NOT covered here and it is not covered in record_activity's PER_ACTIVITY
#              table either, so a project session today records on the shared three fields
#              alone and this file would have nothing to read. Deciding what a project
#              record carries is a pedagogical question about what the project collects, so
#              it goes to Dr. Kay before it goes in here. Do not guess the fields: the
#              2026-08-25 dry run showed what happens when they are unnamed, a session
#              invented its own and validated on the shared three.
#
# Wait for each one rather than building ahead of it. A section summarising an activity that
# has produced no records is a heading with nothing under it, and a student reading their own
# profile learns the course is guessing about them.


# ---------------------------------------------------------------- canonical check names
# The `check` field a student fills is FREE TEXT, and this file counted the exact string
# until 2026-08-28. Measured that day on one real student's profile: FOUR entries appeared
# for two or three real checks, because "Balance" and "Balance (modeled aloud by the
# persona, per the brief)" are different strings. A student reads this file about
# themselves, so a tally that says four when they did two is worse than useless.
#
# WORD boundaries, not substring: "unbounded" is not Bounds and "sourced" is not Source.
# A string naming more than one is information rather than noise, and both are counted. A
# string naming none is kept RAW and shown as the student wrote it, never guessed into a
# bucket, because a wrong bucket is worse than an honest unmatched.
#
# The nine are NOT retyped here. They arrive as an argument, parsed by the caller from
# lecture 1.2 Table 2, per Dr. Kay's instruction that a second copy of the list is drift.
# When no list is available this returns the raw string unchanged, so the profile degrades
# to the old behaviour rather than losing a student's data.
#
# The same rule lives in tools/check_coverage.py, in Python because that one is staff
# tooling. tools/check_names_fixture.tsv is the shared fixture both self-tests read, so the
# two implementations are proven to agree rather than assumed to.
const NINE_FALLBACK = ["Units", "Bounds", "Assumptions", "Prior", "Nudge",
                       "Landmark", "Triangulate", "Balance", "Source"]

"Every one of the nine named as a WORD in `raw`. Empty when it names none."
function canonical_checks(raw::AbstractString, nine = NINE_FALLBACK)
    isempty(strip(raw)) && return String[]
    low = lowercase(raw)
    out = String[]
    for name in nine
        n = lowercase(name)
        for m in eachmatch(Regex(n), low)
            before = m.offset == 1 ? ' ' : low[prevind(low, m.offset)]
            after_i = m.offset + ncodeunits(n)
            after = after_i > ncodeunits(low) ? ' ' : low[after_i]
            if !isletter(before) && !isletter(after)
                push!(out, name); break
            end
        end
    end
    return out
end

const CARRIED_CAP  = 12   # most recent open items kept; older ones stay in the log
const FEEDBACK_CAP = 8
const NOTES_HEAD   = "## Your own notes"

# ---------------------------------------------------------------- minimal JSON reading
# Julia's standard library has no JSON parser and these scripts carry no dependency, which is the
# same reason record_activity.jl hand-writes its own. Every line read here was WRITTEN by
# record_activity.jl, so the shape is known; the one genuinely hard case is a quote inside a
# student's verbatim answer, which is why the string reader honours backslash escapes.

"Read a JSON string starting at the opening quote at `i`. Returns (value, index after closing)."
function jstring(s::AbstractString, i::Int)
    # Indices are STRING indices throughout, moved with nextind. An earlier version collected
    # the string into a Char vector and mixed those positions with string positions, which is
    # correct only while every character is ASCII -- and a student's verbatim answer is exactly
    # where a curly quote or an em dash arrives.
    i > lastindex(s) && return ("", i)
    s[i] == '"' || return ("", i)
    io = IOBuffer(); i = nextind(s, i)
    while i <= lastindex(s)
        c = s[i]
        if c == '\\'
            j = nextind(s, i)
            j > lastindex(s) && break
            n = s[j]
            print(io, n == 'n' ? '\n' : n == 't' ? '\t' : n == 'r' ? '\r' : n)
            i = nextind(s, j)
        elseif c == '"'
            return (String(take!(io)), nextind(s, i))
        else
            print(io, c); i = nextind(s, i)
        end
    end
    return (String(take!(io)), i)
end

"Index just past the colon following \"key\", or 0. Only matches a key at object-key position."
function keypos(s::AbstractString, key::AbstractString)
    pat = "\"" * key * "\""
    start = 1
    while true
        r = findnext(pat, s, start)
        r === nothing && return 0
        j = last(r) + 1
        while j <= lastindex(s) && isspace(s[j]); j = nextind(s, j); end
        j <= lastindex(s) && s[j] == ':' && return nextind(s, j)
        start = last(r) + 1
    end
end

"Skip whitespace from i."
function skipws(s, i)
    while i <= lastindex(s) && isspace(s[i]); i = nextind(s, i); end
    i
end

"The scalar string at `key`, or \"\"."
function sfield(line::AbstractString, key::AbstractString)
    i = keypos(line, key); i == 0 && return ""
    i = skipws(line, i)
    (i <= lastindex(line) && line[i] == '"') || return ""
    first(jstring(line, i))
end

"Every string in the array at `key`. Empty vector if absent or empty."
function afield(line::AbstractString, key::AbstractString)
    out = String[]
    i = keypos(line, key); i == 0 && return out
    i = skipws(line, i)
    (i <= lastindex(line) && line[i] == '[') || return out
    i = nextind(line, i); depth = 1
    while i <= lastindex(line) && depth > 0
        c = line[i]
        if c == '"'
            v, i = jstring(line, i); push!(out, v); continue
        elseif c == '[' ; depth += 1
        elseif c == ']' ; depth -= 1
        end
        i = nextind(line, i)
    end
    out
end

"Raw object slices inside the array at `key`, so a nested field can be read from each."
function ofield(line::AbstractString, key::AbstractString)
    out = String[]
    i = keypos(line, key); i == 0 && return out
    i = skipws(line, i)
    (i <= lastindex(line) && line[i] == '[') || return out
    i = nextind(line, i)
    while i <= lastindex(line)
        c = line[i]
        if c == ']'
            break
        elseif c == '{'
            st = i; depth = 1; i = nextind(line, i)
            while i <= lastindex(line) && depth > 0
                if line[i] == '"'
                    _, i = jstring(line, i); continue
                elseif line[i] == '{' ; depth += 1
                elseif line[i] == '}' ; depth -= 1
                end
                i = nextind(line, i)
            end
            push!(out, line[st:prevind(line, i)])
            continue
        end
        i = nextind(line, i)
    end
    out
end

# ---------------------------------------------------------------- the profile itself

struct Session
    lecture::String
    ended::String
    not_understood::Vector{String}
    wants_covered::Vector{String}
    review_feedback::Vector{String}
    checks::Vector{String}
    first_cut::Vector{Bool}
end

"Every review session in the log, oldest first. Non-review activities and unreadable lines are
skipped rather than fatal: this runs on a student's machine at session start and must never be
the reason a session cannot begin."
function sessions(logpath::AbstractString)
    out = Session[]
    isfile(logpath) || return out
    for line in eachline(logpath)
        isempty(strip(line)) && continue
        try
            sfield(line, "activity") == "review" || continue
            checks = String[]; fc = Bool[]
            for o in ofield(line, "examples_verified")
                c = sfield(o, "check"); isempty(c) || push!(checks, c)
                j = keypos(o, "first_cut_correct")
                j == 0 || push!(fc, startswith(strip(o[j:end]), "true"))
            end
            push!(out, Session(sfield(line, "lecture_id"), first(split(sfield(line, "ended"), "T")),
                               afield(line, "not_understood"), afield(line, "wants_covered"),
                               afield(line, "review_feedback"), checks, fc))
        catch
            continue
        end
    end
    out
end

"The student's own section, carried through verbatim. Absent file or absent section gives the
placeholder, so the heading always exists and they always know the section is theirs."
function own_notes(path::AbstractString)
    default = "_Anything you write below this line is yours and is never overwritten._\n"
    isfile(path) || return default
    txt = read(path, String)
    # ANCHORED TO THE START OF A LINE. The heading is also NAMED in this file's own intro
    # paragraph, so an unanchored search finds that mention first and carries the entire derived
    # body forward as though the student had written it -- which then survives every later
    # rebuild and grows without bound. Caught by the byte-identical and cap cases in the
    # self-test, not by reading the code.
    r = findfirst(Regex("^" * NOTES_HEAD * "\\s*\$", "m"), txt)
    r === nothing && return default
    body = strip(txt[nextind(txt, last(r)):end])
    isempty(body) ? default : body * "\n"
end

function render(ss::Vector{Session}, notes::AbstractString)
    io = IOBuffer()
    println(io, "# What this course knows about your reviews\n")
    println(io, "_Rebuilt from `activity-log.jsonl` every time you run a review. Everything above")
    println(io, "`$NOTES_HEAD` is derived and will be replaced; edit that section instead._\n")

    if isempty(ss)
        println(io, "No reviews recorded yet. This file fills in as you go.\n")
    else
        println(io, "Reviews recorded: **$(length(ss))**, lectures " *
                    join(unique([s.lecture for s in ss if !isempty(s.lecture)]), ", ") * ".\n")
    end

    carried = [(s.lecture, s.ended, t) for s in ss for t in s.not_understood]
    println(io, "## Still open, in your words\n")
    if isempty(carried)
        println(io, "- nothing recorded\n")
    else
        for (lec, day, t) in carried[max(1, end - CARRIED_CAP + 1):end]
            println(io, "- **$lec** ($day) — $t")
        end
        length(carried) > CARRIED_CAP &&
            println(io, "\n_$(length(carried) - CARRIED_CAP) older item(s) not shown; they are in the log._")
        println(io)
    end

    wants = [(s.lecture, t) for s in ss for t in s.wants_covered]
    println(io, "## You asked to have these gone over\n")
    println(io, isempty(wants) ? "- nothing recorded\n" :
                join(["- **$lec** — $t" for (lec, t) in wants], "\n") * "\n")

    tally = Dict{String,Int}()
    for s in ss, c in s.checks
        for name in (isempty(canonical_checks(c)) ? [c] : canonical_checks(c))
            tally[name] = get(tally, name, 0) + 1
        end
    end
    println(io, "## Checks you reach for\n")
    if isempty(tally)
        println(io, "- nothing recorded yet\n")
    else
        for (c, n) in sort(collect(tally), by = x -> (-x[2], x[1]))
            println(io, "- $c — $n")
        end
        allfc = [b for s in ss for b in s.first_cut]
        isempty(allfc) ||
            println(io, "\nFirst answer right before computing: **$(count(allfc)) of $(length(allfc))**.")
        println(io)
    end

    fb = [t for s in ss for t in s.review_feedback]
    println(io, "## What you said about the review itself\n")
    println(io, isempty(fb) ? "- nothing recorded\n" :
                join(["- $t" for t in fb[max(1, end - FEEDBACK_CAP + 1):end]], "\n") * "\n")

    println(io, NOTES_HEAD, "\n")
    println(io, notes)
    String(take!(io))
end

function build(workdir::AbstractString)
    logp = joinpath(workdir, "activity-log.jsonl")
    outp = joinpath(workdir, "profile.md")
    text = render(sessions(logp), own_notes(outp))
    write(outp, text)
    outp
end

if abspath(PROGRAM_FILE) == @__FILE__
    work = length(ARGS) >= 1 ? ARGS[1] : joinpath(pwd(), "work")
    isdir(work) || (println(stderr, "build_profile: no such directory: $work"); exit(1))
    println("wrote ", build(work))
end
