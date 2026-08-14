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

struct Finding
    line::Int
    severity::String   # "ERROR" or "warn"
    message::String
end

# a keyword line: optional markdown bold, the keyword, a colon, then the rest
const KW_RE   = r"^\s*(?:\*\*)?([a-z][a-z ]*?):(?:\*\*)?\s*(.*?)\s*\\?$"
const ITEM_RE = r"^\s*\(([a-z])\)\s*(.*)$"

function findings(path::AbstractString)
    out = Finding[]
    lines = readlines(path)
    slots = Tuple{Int,String,String}[]     # (lineno, keyword, inline content)
    items = Dict{Int,Vector{Tuple{Int,String}}}()   # slot lineno -> items

    cur = 0
    for (i, raw) in enumerate(lines)
        m = match(KW_RE, raw)
        if m !== nothing && lowercase(m[1]) in vcat(KNOWN, ["find"])
            kw = lowercase(m[1])
            push!(slots, (i, kw, String(m[2])))
            items[i] = Tuple{Int,String}[]
            cur = i
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
        return out
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
                push!(out, Finding(ln, "ERROR", "$kw: is empty"))
            elseif !isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: takes exactly one entity but has a lettered list; " *
                    "if it needs several, name the one composite thing they make up"))
            end
        elseif kw in LISTED
            if lowercase(inline) == "none"
                # legitimate and informative
            elseif !isempty(inline) && isempty(its)
                push!(out, Finding(ln, "ERROR",
                    "$kw: is written inline; it takes a lettered list (a) (b) (c), " *
                    "one per line, even at a single item"))
            elseif isempty(its)
                push!(out, Finding(ln, "ERROR", "$kw: has no items"))
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
    for k in 2:length(ranks)
        if ranks[k][2] < ranks[k-1][2]
            push!(out, Finding(ranks[k][1], "warn",
                "keyword is out of order; the order is " * join(ORDER, ", ")))
        end
    end

    # coherence between slots
    has(k) = k in seen
    if !has("return")
        push!(out, Finding(0, "ERROR", "no return: -- every model returns something"))
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
            "an objective with no solve for: -- if something is optimized, " *
            "something is being decided"))
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
    return out
end

function main(args)
    if length(args) != 1
        println("usage: julia check_model.jl <model file>")
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
    for f in sort(fs, by = x -> (x.line, x.severity))
        nerr += f.severity == "ERROR" ? 1 : 0
        where_ = f.line == 0 ? "  --  " : lpad(string(f.line), 4) * ": "
        println("$(rpad(f.severity, 5)) $where_$(f.message)")
    end
    println()
    println("$(length(fs)) finding(s), $nerr error(s), in $path")
    println("Format reference: https://mgkay.github.io/ise754f26/model-reference.html")
    return nerr == 0 ? 0 : 1
end

exit(main(ARGS))
