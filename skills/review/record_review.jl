#!/usr/bin/env julia
#
# Stop hook: persist the review session's structured record.
#
# WHY A HOOK AND NOT THE MODEL. The record is written by a deterministic script reading the
# block the persona emitted, rather than by asking the model to remember to save something
# after thirty turns of conversation. The student's token budget belongs to the
# conversation, not to bookkeeping.
#
# WHY JULIA, AND NOT PYTHON. Julia is the only scripting runtime the course setup
# guarantees: the bootstrap installs Git, VS Code, Julia and Claude Code, and it explicitly
# does NOT install Python, treating any existing Python as the student's own. A Python hook
# would fail silently on most machines, and the failure would look like a student who never
# ran the activity. Stdlib only, so it runs without the project environment instantiated.
#
# WHY JSON LINES. Julia's standard library has no JSON parser, and pulling in JSON.jl to
# rewrite an array on every append would add a dependency for no benefit. One record per
# line is append-only, needs no parsing to write, and one malformed line cannot corrupt the
# records around it. The instructor's roll-up parses it on a machine that does have the
# tools.
#
# NO PII, BY CONSTRUCTION. The log carries no name: the private repository it lands in
# already identifies the student. Nothing here copies the raw transcript, which could sweep
# in unrelated local session content.
#
# FAILURE IS QUIET. A missing or malformed block writes nothing and leaves one line in
# review-log.error. It never interrupts the session: this is ungraded formative work, and a
# recorder that derails a study session to complain about its own schema has its priorities
# backwards.

# `examples_verified` is required because verifying the lecture's examples IS the activity,
# so a block without it is not a record of this session -- and an absent field would be
# indistinguishable, in the roll-up, from a session that covered no examples. A block that
# omits any of these is dropped with the field named in review-log.error, which is
# diagnosable; a record that quietly under-reports is not.
const REQUIRED = ["lecture_id", "questions", "examples_verified",
                  "big_idea_reached", "planted_error_caught"]
const OUT_NAME = "review-log.jsonl"

"The student's work repository, or the working directory if the layout is not standard."
function find_work_dir()
    dir = pwd()
    while true
        work = joinpath(dir, "work")
        isdir(joinpath(work, ".git")) && return work
        basename(dir) == "work" && isdir(joinpath(dir, ".git")) && return dir
        parent = dirname(dir)
        parent == dir && return pwd()
        dir = parent
    end
end

function note_error(work, msg)
    try
        open(joinpath(work, "review-log.error"), "a") do io
            println(io, "$(round(Int, time()))  $msg")
        end
    catch
    end
end

"""
Extract the LAST ```review-log fenced block. Deliberately a distinctive tag rather than
plain ```json, so an unrelated JSON block in the conversation cannot be mistaken for the
record.
"""
function last_block(text)
    blocks = String[]
    for m in eachmatch(r"```review-log\s*\n(.*?)\n```"s, text)
        push!(blocks, m.captures[1])
    end
    isempty(blocks) ? nothing : blocks[end]
end

function main()
    stdin_text = try read(stdin, String) catch; "" end

    # Claude Code hands a Stop hook JSON on stdin carrying the transcript PATH, not its
    # contents. Pulled out by pattern rather than by parsing, for the same
    # no-JSON-dependency reason as above.
    text = stdin_text
    m = match(r"\"transcript_path\"\s*:\s*\"([^\"]+)\"", stdin_text)
    path = m === nothing ? get(ENV, "CLAUDE_TRANSCRIPT_PATH", "") : replace(m.captures[1], "\\\\" => "\\")
    if !isempty(path) && isfile(path)
        text = try read(path, String) catch; stdin_text end
    end

    work = find_work_dir()
    block = last_block(text)

    # No block is the ordinary case for every session that was not a review, so stay silent
    # rather than littering the work repository on each one.
    block === nothing && return 0

    missing_fields = [k for k in REQUIRED if !occursin("\"$k\"", block)]
    if !isempty(missing_fields)
        note_error(work, "review-log block missing field(s): " * join(missing_fields, ", "))
        return 0
    end

    # Collapsed to one line, since the file is one record per line. The block is already
    # JSON as the persona emitted it; this only reshapes whitespace.
    oneline = replace(strip(block), r"\s*\n\s*" => " ")

    try
        open(joinpath(work, OUT_NAME), "a") do io
            println(io, oneline)
        end
    catch err
        note_error(work, "could not write $OUT_NAME: $err")
    end
    return 0
end

exit(main())
