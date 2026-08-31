# check_model.jl -- check a model statement against the ISE 754 model format.
#
#   julia ../materials/env/check_model.jl model.md
#
# Reports what does not conform and exits nonzero if anything is an error, so it
# can be used in a loop. Standard library only, and ASCII-only output, because a
# Windows console will not reliably print anything else.
#
# The format it checks is documented at
#   https://mgkay.github.io/ise754f26/model-reference.html
# Keep the two in step: this script is the mechanical half of that page, and it
# only checks what is decidable from the text. It cannot tell whether a
# constraint is really an assumption; that judgment is the whole point of the
# reference and stays with the reader.

const SINGULAR = ["minimize", "maximize", "return"]
const LISTED   = ["solve for", "subject to", "assumptions"]
const DEFLIST  = ["where"]
const KNOWN    = vcat(SINGULAR, LISTED, DEFLIST)
const ORDER    = ["minimize", "maximize", "solve for", "subject to",
                  "return", "assumptions", "where"]

# What each slot holds, in the words the reference uses, so a message can say
# what to write rather than only that something is wrong.
const WHAT = Dict(
    "minimize"    => "what is being optimized",
    "maximize"    => "what is being optimized",
    "solve for"   => "each unknown, and what values it may take",
    "subject to"  => "what restricts the solutions",
    "return"      => "what comes back",
    "assumptions" => "what must be true about the world",
    "where"       => "the given data and symbol meanings",
)

struct Finding
    line::Int
    severity::String   # "ERROR" or "warn"
    message::String
end

# a keyword line: optional markdown bold, the keyword, a colon, then the rest
# A keyword line, tolerating a Quarto span wrapper. In a lecture, a model that
# is presented as a change from a previous one marks the changed slots with
# [ ... ]{.model-add} / {.model-del}, so the keyword can arrive bracketed:
#   [**subject to:**]{.model-add}
# Without the optional bracket and attribute below, such a slot is invisible and
# the model is reported as missing a keyword it plainly has.
const KW_RE   = r"^\s*\[?\s*(?:\*\*)?([a-z][a-z ]*?):(?:\*\*)?\]?(?:\{[^}]*\})?\s*(.*?)\s*\\?$"
const ITEM_RE = r"^\s*\[?\s*\(([a-z])\)\s*(.*)$"   # tolerates [ ... ]{.model-add}

# --- Quarto lecture support -----------------------------------------------
# The same rules have to hold for the models printed in the lectures, so this
# script is the single implementation and the lecture linter calls it rather
# than restating the rules. In a .qmd, a model is a fenced div carrying an
# #mdl- identifier. A `model-skeleton` block is NOT a model: it is the template
# that teaches the shape, written with ... placeholders, so it is skipped.
const DIV_CLOSE = r"^(:{3,})[ \t]*$"
const DIV_OPEN  = r"^(:{3,})[ \t]*(\S.*)$"

"Line ranges of the model callouts in a .qmd, skipping skeleton templates."
function model_ranges(lines::Vector{String})
    ranges = Tuple{Int,Int}[]
    stack = Tuple{Int,String,Int}[]        # (colon count, attrs, start line)
    for (i, raw) in enumerate(lines)
        if match(DIV_CLOSE, raw) !== nothing
            isempty(stack) && continue
            _, attrs, start = pop!(stack)
            if occursin("#mdl-", attrs) &&
               !any(occursin("model-skeleton", a) for (_, a, _) in stack)
                push!(ranges, (start, i))
            end
        else
            m = match(DIV_OPEN, raw)
            m === nothing && continue
            push!(stack, (length(m[1]), String(m[2]), i))
        end
    end
    return ranges
end

function findings(path::AbstractString)
    all_lines = readlines(path)
    if endswith(lowercase(path), ".qmd")
        out = Finding[]
        for (a, b) in model_ranges(all_lines)
            append!(out, check_slice(all_lines[a:b], a - 1))
        end
        return out                          # no callouts means nothing to say
    end
    return check_slice(all_lines, 0)
end

function check_slice(lines::Vector{String}, offset::Int)
    out = Finding[]
    # Findings are collected against slice-relative line numbers and shifted to
    # absolute ones on the way out. A model-level finding (line 0) is reported
    # against the model's opening line when this is a slice of a lecture.
    shift(fs) = [Finding(f.line == 0 ? (offset == 0 ? 0 : offset + 1)
                                     : f.line + offset,
                         f.severity, f.message) for f in fs]
    slots = Tuple{Int,String,String}[]     # (lineno, keyword, inline content)
    items = Dict{Int,Vector{Tuple{Int,String}}}()   # slot lineno -> items

    cur = 0
    for (i, raw) in enumerate(lines)
        m = match(KW_RE, raw)
        if m !== nothing
            kw = lowercase(m[1])
            if kw in vcat(KNOWN, ["find"])
                push!(slots, (i, kw, String(m[2])))
                items[i] = Tuple{Int,String}[]
                cur = i
                continue
            end
            # THE VOCABULARY IS CLOSED, AND AN UNRECOGNISED KEYWORD IS AN ERROR
            # RATHER THAN A LINE TO SKIP (2026-08-31, from `settle:` in 2.3).
            #
            # This test used to be part of the condition above, so a keyword that
            # was not in KNOWN simply failed to match and the line was discarded:
            # not reported, absent from the ORDER check, and counting toward no
            # slot, so every coherence check still passed. `settle:` sat in
            # lecture 2.3 for a week and this script called the file conforming.
            #
            # `find:` was caught only because it had been re-added to the
            # recognised list SPECIFICALLY so it could be errored on -- the
            # retirement was mechanised as a named special case instead of as an
            # instance of the general rule, which is why the general rule caught
            # nothing. A whitelist parser accepts everything outside the
            # whitelist unless the else-branch is written. This is that branch.
            push!(out, Finding(i, "ERROR",
                "\"$kw:\" is not a model keyword. The vocabulary is closed: " *
                "minimize: or maximize:, solve for:, subject to:, return:, " *
                "assumptions:, and where: once a model carries symbols. If it " *
                "names what the model hands back that is return:; if it names " *
                "an unknown that is solve for:"))
            cur = 0     # its lettered items belong to no slot; do not misattribute
            continue
        end
        mi = match(ITEM_RE, raw)
        if mi !== nothing && cur > 0
            push!(items[cur], (i, String(mi[2])))
        elseif isempty(strip(raw))
            cur = 0                         # a blank line closes the slot
        end
    end

    if isempty(slots)
        push!(out, Finding(0, "ERROR",
            "no model keywords found; a model needs at least return: and assumptions:"))
        return shift(out)
    end

    seen = String[]
    for (ln, kw, inline) in slots
        if kw == "find"
            push!(out, Finding(ln, "ERROR",
                "find: is retired -- use solve for: for the unknowns"))
            continue
        end
        push!(seen, kw)
        its = items[ln]

        if kw in SINGULAR
            if isempty(inline) && isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: is empty; it holds $(WHAT[kw]), written on the same " *
                    "line as the keyword and as one thing, not a list"))
            elseif !isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: takes exactly one entity but has a lettered list; " *
                    "if it needs several, name the one composite thing they make up"))
            end
        elseif kw in LISTED
            if startswith(lowercase(inline), "none")
                # Legitimate and informative. A trailing clause is allowed, since
                # "none, because ..." says more than a bare "none" and an empty
                # slot is a finding about the problem that is worth explaining.
            elseif !isempty(inline) && isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: is written inline; it takes a lettered list (a) (b) (c), " *
                    "one per line, even at a single item"))
            elseif isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: has nothing under it. Either list $(WHAT[kw]) as " *
                    "\"(a) ...\" one item per line, or write \"$kw: none\" if " *
                    "there genuinely are none, which is a real finding about " *
                    "the problem rather than an omission"))
            else
                for (k, (iln, _)) in enumerate(its)
                    want = 'a' + k - 1
                    got  = match(ITEM_RE, lines[iln])[1][1]
                    if got != want
                        push!(out, Finding(iln, "warn",
                            "item is ($got) where ($want) was expected; " *
                            "letters run in order from (a)"))
                    end
                end
                if kw == "subject to"
                    for (iln, body) in its
                        if match(r"^[A-Za-z][A-Za-z0-9 _-]*:", body) === nothing
                            push!(out, Finding(iln, "warn",
                                "constraint has no name; write \"(a) name: text\", " *
                                "since the name is what it is called in the code"))
                        end
                    end
                end
            end
        elseif kw in DEFLIST
            if !isempty(its)
                push!(out, Finding(ln, "warn",
                    "where: is a definition list keyed by symbol, not a lettered " *
                    "list; drop the (a) (b) letters"))
            end
        end
    end

    # order
    ranks = [(ln, findfirst(==(kw), ORDER)) for (ln, kw, _) in slots
             if kw in KNOWN]
    for (prev, cur) in zip(ranks, Iterators.drop(ranks, 1))
        if cur[2] < prev[2]
            push!(out, Finding(cur[1], "warn",
                "keyword is out of order; the order is " * join(ORDER, ", ")))
        end
    end

    # coherence between slots
    has(k) = k in seen
    if !has("return")
        push!(out, Finding(0, "ERROR",
            "no return:. Every model returns something, so add a \"return:\" line " *
            "naming the one thing handed back; if it seems to need several, name " *
            "the one composite thing they make up"))
    end
    if !has("assumptions")
        push!(out, Finding(0, "warn",
            "no assumptions: -- every model simplifies something; say what"))
    end
    objective = has("minimize") || has("maximize")
    if has("minimize") && has("maximize")
        push!(out, Finding(0, "ERROR", "both minimize: and maximize: -- pick one"))
    end
    if objective && !has("solve for")
        push!(out, Finding(0, "ERROR",
            "an objective but no solve for:. If something is being optimized then " *
            "something is being decided, so add a \"solve for:\" list naming each " *
            "unknown and what values it may take"))
    end
    if has("solve for") && !has("subject to")
        push!(out, Finding(0, "warn",
            "solve for: with no subject to: -- write \"subject to: none\" if the " *
            "problem really is unconstrained, which is worth stating"))
    end
    if !objective && !has("solve for") && has("subject to")
        push!(out, Finding(0, "warn",
            "subject to: in a model that decides nothing; a descriptive model " *
            "has no solution to constrain"))
    end
    return shift(out)
end

"""
The negative control. A check that cannot be shown to FAIL is not a check, and
this script had no way to demonstrate it: it was run only on files expected to
pass, so the day the closed-vocabulary rule turned out to be missing entirely,
nothing about the output looked different. Each case below states the input and
the verdict it must produce, so a later edit that quietly stops reporting
something fails here instead of in a lecture.

    julia check_model.jl --self-test
"""
function self_test()
    conforming = [
        "minimize: total weighted distance",
        "",
        "solve for:",
        "(a) the facility location, any point in the plane",
        "",
        "subject to: none",
        "",
        "return: the facility location",
        "",
        "assumptions:",
        "(a) demand is at the given points",
    ]
    unknown_kw(fs)  = any(occursin("is not a model keyword", f.message) for f in fs)
    retired_find(fs) = any(occursin("find: is retired", f.message) for f in fs)

    cases = [
        # (name, lines, predicate on the findings, what the predicate means)
        ("a conforming model reports no unknown keyword",
         conforming, fs -> !unknown_kw(fs), "must not fire"),
        ("an invented keyword is an ERROR",
         vcat(["settle: which facilities share a site"], conforming),
         fs -> unknown_kw(fs) &&
               any(f.severity == "ERROR" && occursin("settle", f.message)
                   for f in fs),
         "must fire, as an ERROR, naming the keyword"),
        ("an invented keyword written in markdown bold is an ERROR",
         vcat(["**settle:** which facilities share a site"], conforming),
         fs -> unknown_kw(fs), "must fire on the lecture's bold slot form"),
        ("find: keeps its own retirement message, not the generic one",
         vcat(["find: the unknowns"], conforming),
         fs -> retired_find(fs) && !unknown_kw(fs),
         "must say find: is retired and point at solve for:"),
        ("a model of nothing but an invented keyword still reports it",
         ["settle: everything"],
         fs -> unknown_kw(fs), "must fire even with no recognised slot"),
    ]

    nfail = 0
    for (name, lines, pred, meant) in cases
        fs = check_slice(lines, 0)
        ok = pred(fs)
        nfail += ok ? 0 : 1
        println("$(ok ? "pass" : "FAIL")  $name")
        if !ok
            println("        the rule $meant, and did not. Findings:")
            isempty(fs) && println("          (none)")
            for f in fs
                println("          $(f.severity) $(f.line): $(f.message)")
            end
        end
    end
    println()
    println("$(length(cases)) case(s), $nfail failure(s)")
    return nfail == 0 ? 0 : 1
end

function main(args)
    if length(args) == 1 && args[1] == "--self-test"
        return self_test()
    end
    if length(args) != 1
        println("usage: julia check_model.jl <model file>")
        println("       julia check_model.jl --self-test")
        return 2
    end
    path = args[1]
    if !isfile(path)
        println("ERROR  no such file: $path")
        return 2
    end
    fs = findings(path)
    if isempty(fs)
        println("OK  $path conforms to the model format.")
        println("    Note: the format is checked, not the modeling. Whether a")
        println("    constraint should have been an assumption is still yours.")
        return 0
    end
    nerr = 0
    src = readlines(path)
    for f in sort(fs, by = x -> (x.line, x.severity))
        nerr += f.severity == "ERROR" ? 1 : 0
        where_ = f.line == 0 ? "  --  " : lpad(string(f.line), 4) * ": "
        println("$(rpad(f.severity, 5)) $where_$(f.message)")
        # Echo the offending line, so the message does not have to be matched up
        # against the file by hand. Kept on its own line so a caller parsing the
        # findings sees only the lines that begin with a severity.
        if 1 <= f.line <= length(src)
            text = strip(src[f.line])
            !isempty(text) && println("           > $text")
        end
    end
    println()
    println("$(length(fs)) finding(s), $nerr error(s), in $path")
    println("Format reference: https://mgkay.github.io/ise754f26/model-reference.html")
    return nerr == 0 ? 0 : 1
end

exit(main(ARGS))
