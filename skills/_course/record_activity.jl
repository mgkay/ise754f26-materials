#!/usr/bin/env julia
#
# Stop hook: persist ANY course activity's record, and tell the student to submit it.
#
# ONE HOOK FOR EVERY SKILL. This replaces the per-skill recorder. Three activity skills
# would otherwise mean three Stop hooks firing on every session end and three near-identical
# Julia scripts drifting apart, and the install procedure would change each time a skill was
# added -- which the skills README explicitly promises it will not. The activity names
# itself inside the record instead, so adding /homework or /project needs no new plumbing,
# no new hook, and no change to what a student installs.
#
# WHY A HOOK AND NOT THE MODEL. The record is written by a deterministic script reading the
# block the persona emitted, rather than by asking the model to remember to save something
# after thirty turns. The student's token budget belongs to the conversation.
#
# WHY JULIA, AND NOT PYTHON. Julia is the only scripting runtime the course setup
# guarantees: the bootstrap installs Git, VS Code, Julia and Claude Code, and it explicitly
# does NOT install Python, treating any existing Python as the student's own. A Python hook
# would fail silently on most machines, and the failure would look like a student who never
# ran the activity. Stdlib only, so it runs without the project environment instantiated.
#
# WHY JSON LINES. Julia's standard library has no JSON parser, and rewriting an array on
# every append would add a dependency for no benefit. One record per line is append-only,
# needs no parsing to write, and one malformed line cannot corrupt the records around it.
#
# NO PII, BY CONSTRUCTION. The log carries no name: the private repository it lands in
# already identifies the student. Nothing here copies the raw transcript, which could sweep
# in unrelated local session content.
#
# HOW THE STUDENT IS TOLD TO SUBMIT, and why it is done this way. A Stop hook's stdout is
# written to the debug log and is NOT shown to the user (Claude Code hooks documentation,
# "Exit code behavior"; accessed 2026-08-16), so printing the instruction would reach
# nobody. Exit code 2 would block the stop and continue the conversation, but a hook that
# refuses to let a session end until a push succeeds traps any student whose network or
# credentials are not working. The documented field `systemMessage` is a "Warning message
# shown to the user", so the hook exits 0 and returns one: the student sees it every time,
# nothing blocks, and there is no loop to get stuck in.
#
# The message fires on every recorded session, which is correct rather than noisy -- the
# hook has just written a line, so the record is by definition uncommitted at that moment.
# An activity that is recorded but never pushed is, from the instructor's side, an activity
# that did not happen.
#
# FAILURE IS QUIET OTHERWISE. A missing or malformed block writes nothing and leaves one
# line in activity-log.error. It never interrupts the session: this is ungraded formative
# work, and a recorder that derails a study session to complain about its own schema has its
# priorities backwards.

const OUT_NAME = "activity-log.jsonl"
const ERR_NAME = "activity-log.error"

# Fields every record must carry, plus the extra ones each activity requires. Per-activity
# strictness lives here rather than in each skill, so one file says what a complete record
# of each activity looks like. An activity not listed is recorded on the shared fields
# alone, which is what lets a new skill land before this table is updated.
const SHARED = ["activity", "started", "ended"]
const PER_ACTIVITY = Dict(
    "review" => ["lecture_id", "questions", "examples_verified",
                 "big_idea_reached", "planted_error_caught"],
)

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
        open(joinpath(work, ERR_NAME), "a") do io
            println(io, "$(round(Int, time()))  $msg")
        end
    catch
    end
end

"""
Extract the LAST ```course-log fenced block. Deliberately a distinctive tag rather than
plain ```json, so an unrelated JSON block in the conversation cannot be mistaken for the
record.
"""
function last_block(text)
    blocks = String[]
    for m in eachmatch(r"```course-log\s*\n(.*?)\n```"s, text)
        push!(blocks, m.captures[1])
    end
    isempty(blocks) ? nothing : blocks[end]
end

"The value of a top-level string field, or nothing. Enough for `activity`; not a parser."
function field(block, key)
    m = match(Regex("\"$key\"\\s*:\\s*\"([^\"]*)\""), block)
    m === nothing ? nothing : m.captures[1]
end

"""
Does this block look like the SKILL's own TEMPLATE rather than a real record?

WHY THIS IS NECESSARY. `last_block` scans the whole transcript, and the skill file is IN
the transcript -- the assistant read it to run the activity. Its Step 4 shows a filled-in
example inside a ```course-log fence. So a session that ends WITHOUT the assistant emitting
a real block still has exactly one block available, the template, and the hook recorded it.

Measured 2026-08-20 on a real /review 1.3 session that stopped after the first question:
activity-log.jsonl received the template verbatim, "started": "<ISO 8601>", together with
first_cut_correct true, big_idea_reached true and planted_error_caught true. An abandoned
session therefore wrote a record indistinguishable from a flawless one, which is worse than
writing nothing: it is silent, plausible, and wrong in the direction that flatters.

Presence-of-field checking cannot see this, because the template HAS every field. What
separates them is the SHAPE of the values, so that is what is checked.
"""
function looks_like_template(block)
    # `started` and `ended` are the tell: a real record carries a timestamp, the template
    # carries the words describing one.
    for key in ("started", "ended")
        v = field(block, key)
        v === nothing && return true
        occursin(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}", v) || return true
    end
    # The template also offers alternatives with a bare `|`, which is not JSON at all.
    occursin(r"\"\s*\|\s*\"", block) && return true
    return false
end

"Minimal JSON string escaping, for text this script composes."
esc(s) = replace(s, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\r" => "")

"Unpushed commits in `work`, or nothing when that cannot be determined (no upstream yet)."
function unpushed(work)
    try
        # stderr goes to devnull deliberately. A `try` catches an exception; it does not
        # silence a child process, so without this a repository with no upstream prints
        # git's own "fatal:" line to the student's terminal while this function is
        # correctly returning nothing.
        cmd = pipeline(Cmd(`git rev-list --count "@{u}"..HEAD`; dir = work), stderr = devnull)
        out = read(cmd, String)
        return tryparse(Int, strip(out))
    catch
        return nothing
    end
end

"""
Undo one level of JSON string escaping, in ONE left-to-right pass.

WHY A PASS AND NOT THREE `replace` CALLS. This was three independent replacements
(\\r\\n, \\n, then \\") and that is wrong on any text containing a BACKSLASH, because
a later pass cannot see where an earlier escape ended. A quote inside the student's
own words reaches the transcript as the four characters \\ \\ \\ " -- an escaped
backslash followed by an escaped quote. Replacing the two-character \" anywhere it
appears consumes the SECOND and THIRD characters, leaving \\ " : a literal backslash
and a bare quote, which closes the JSON string early. The recorded line is then
unparseable, and it is unparseable in the one field the skill calls the richest
signal in the log, `questions`, which it instructs be recorded verbatim.

Measured 2026-08-20 on a real /review 1.3 session whose student said: You've
referred to a "Prior check" by name. The line written to activity-log.jsonl failed
json.loads at column 279. A single pass consumes \\ as a unit before it can be
mistaken for the start of \", so the same input round-trips correctly.

Only the escapes the transcript actually produces are handled; anything else is
passed through unchanged rather than guessed at.
"""
function json_unescape(s::AbstractString)
    out = IOBuffer()
    i = firstindex(s)
    stop = lastindex(s)
    while i <= stop
        c = s[i]
        j = i < stop ? nextind(s, i) : nothing
        if c == '\\' && j !== nothing
            n = s[j]
            k = nextind(s, j)
            if     n == 'n';  write(out, '\n'); i = k; continue
            elseif n == 'r';                     i = k; continue   # \r\n collapses to \n
            elseif n == 't';  write(out, '\t'); i = k; continue
            elseif n == '"';  write(out, '"');  i = k; continue
            elseif n == '\\'; write(out, '\\'); i = k; continue
            end
        end
        write(out, c)
        i = i < stop ? nextind(s, i) : stop + 1
    end
    return String(take!(out))
end

function main()
    stdin_text = try read(stdin, String) catch; "" end

    # Claude Code hands a Stop hook JSON on stdin carrying the transcript PATH, not its
    # contents. Pulled out by pattern rather than by parsing, for the same
    # no-JSON-dependency reason as above.
    text = stdin_text
    m = match(r"\"transcript_path\"\s*:\s*\"([^\"]+)\"", stdin_text)
    path = m === nothing ? get(ENV, "CLAUDE_TRANSCRIPT_PATH", "") :
                           replace(m.captures[1], "\\\\" => "\\")
    if !isempty(path) && isfile(path)
        text = try read(path, String) catch; stdin_text end
    end

    # THE TRANSCRIPT IS JSON LINES, so the assistant's text is stored JSON-ESCAPED: a
    # fenced block's newlines are the two characters \n and its quotes are \". Both
    # regexes below need real characters -- last_block requires a real newline after
    # ```course-log, and the field check requires unescaped quotes -- so without this
    # every match silently returns nothing and the hook takes its "not a course
    # activity" path. That failure is indistinguishable from a session that never
    # happened, which is the one outcome this file's header says it must never produce.
    # Stdlib only, no JSON parser, consistent with the rest of this script.
    text = json_unescape(text)

    work = find_work_dir()
    block = last_block(text)

    # No block is the ordinary case for every session that was not a course activity, so
    # stay silent rather than littering the work repository on each one.
    block === nothing && return 0

    activity = field(block, "activity")
    if activity === nothing
        note_error(work, "course-log block names no activity")
        return 0
    end

    required = vcat(SHARED, get(PER_ACTIVITY, activity, String[]))
    missing_fields = [k for k in required if !occursin("\"$k\"", block)]
    if !isempty(missing_fields)
        note_error(work, "$activity record missing field(s): " * join(missing_fields, ", "))
        return 0
    end

    # Collapsed to one line, since the file is one record per line. The block is already
    # JSON as the persona emitted it; this only reshapes whitespace.
    if looks_like_template(block)
        note_error(work, "$activity block looks like the skill's template, not a session " *
                         "record (no real timestamps); nothing recorded")
        return 0
    end

    oneline = replace(strip(block), r"\s*\n\s*" => " ")

    # DO NOT RECORD THE SAME SESSION TWICE.
    #
    # This hook reads the LAST course-log block in the transcript, and Stop fires every time
    # the assistant finishes a turn. So once a session has emitted its block, every later
    # stop in that same session finds the same block and appends it again. Measured
    # 2026-08-21 in the first interactive dry run: one review produced two byte-identical
    # records, sha 66943cfb4d9e, in a log that also held twelve template lines.
    #
    # Duplicates are worse than they look. They do not corrupt a record, they inflate the
    # COUNT -- so "how many reviews has this student completed" becomes unreliable, and it is
    # unreliable in the flattering direction, which is the hard kind to notice.
    #
    # The guard is a comparison against what is already the last line, not a full scan: the
    # duplicate always lands adjacent, because it comes from a later stop in the same session.
    # A genuine second review of the same lecture differs in `ended` at minimum, so it is not
    # suppressed.
    out_path = joinpath(work, OUT_NAME)
    if isfile(out_path)
        last = ""
        try
            for ln in eachline(out_path)
                isempty(strip(ln)) || (last = strip(ln))
            end
        catch
        end
        if last == strip(oneline)
            return 0   # already recorded this session; say nothing, change nothing
        end
    end

    try
        open(out_path, "a") do io
            println(io, oneline)
        end
    catch err
        note_error(work, "could not write $OUT_NAME: $err")
        return 0
    end

    # Tell the student to submit it. See the header for why this is a systemMessage rather
    # than stdout or a blocking exit.
    ahead = unpushed(work)
    extra = (ahead !== nothing && ahead > 0) ?
            " You also have $ahead commit(s) not yet pushed." : ""
    msg = "Your $activity session is recorded in $OUT_NAME, but it is NOT submitted " *
          "until it is pushed.$extra From your ISE754/work folder: git add -A, then " *
          "git commit -m \"$activity record\", then git push."
    println("{\"systemMessage\": \"" * esc(msg) * "\"}")
    return 0
end

exit(main())
