#!/usr/bin/env julia
#
# ISE 754 - Logistics Engineering, Fall 2026
# bootstrap_check.jl - verify that this machine is ready for the course.
#
# Output is deliberately ASCII only. A Windows console captures this script's
# output through a legacy code page, which corrupted an em dash in the title
# line to a mojibake sequence in a real run, and that text is what a student
# pastes into Moodle.
#
# Run it:   julia materials/env/bootstrap_check.jl
#
# It performs eleven checks and prints READY, or a numbered list of what needs
# attention. Three properties are deliberate and worth preserving if this file
# is edited:
#
#   1. It INSTALLS NOTHING and CHANGES NOTHING. It is safe to run at any time,
#      as often as wanted. Its only write is bootstrap-output.txt, the report
#      it is asked to leave behind.
#   2. It INVOKES each tool rather than looking for that tool's files. A file
#      on disk does not prove a working command; running it does.
#   3. It reports UNKNOWN rather than guessing. A check that cannot determine
#      an answer says so, and an UNKNOWN never counts as a pass.
#
# Only the Julia standard library is used, so this runs even when the course
# environment has not been instantiated yet.

using TOML
using Pkg

const PIN        = v"1.12.6"
const REPO_SLUG  = "mgkay/ise754f26-materials"
const JULIA_EXT  = "julialang.language-julia"
const CLAUDE_EXT = "anthropic.claude-code"

# On Windows the VS Code command line tool is the `code.cmd` shim in the
# install's `bin` directory. A bare `code` can instead resolve to `Code.exe`,
# the GUI executable, which OPENS A WINDOW rather than answering the command.
# Which one wins depends on PATH order, and therefore on whether VS Code was
# installed per-user or per-machine: observed launching windows on a
# system-scope install and answering correctly on a user-scope one. Always
# probe the shim, so this script keeps its promise to change nothing.
const CODE_CMD = Sys.iswindows() ? "code.cmd" : "code"

const ENV_DIR   = @__DIR__                # ISE754/materials/env
const MATERIALS = dirname(ENV_DIR)        # ISE754/materials
const ROOT      = dirname(MATERIALS)      # ISE754

# ---------------------------------------------------------------- utilities

"""Run a command, capturing output. Returns (ok, combined output).

On Windows the command is routed through `cmd /c` so that batch-file shims
such as `code.cmd` resolve the same way they do when typed by hand.
"""
function probe(parts::Vector{String})
    cmd = Sys.iswindows() ? Cmd(vcat(["cmd", "/c"], parts)) : Cmd(parts)
    out = IOBuffer()
    try
        run(pipeline(cmd; stdout = out, stderr = out))
        return (true, String(strip(String(take!(out)))))
    catch
        return (false, String(strip(String(take!(out)))))
    end
end

first_line(s) = isempty(s) ? "" : strip(first(split(s, '\n')))

"""Describe a failed probe honestly.

"Not installed" and "installed but refusing to run" need different fixes, and
conflating them sends a student off to reinstall something they already have.
A tool that printed anything before failing is present; it is the message it
printed that matters, so it is passed through verbatim.
"""
function probe_failure(name::AbstractString, out::AbstractString,
                       absent_fix::AbstractString)
    isempty(out) && return ("the `$name` command was not found", absent_fix)
    return ("`$name` is present, but did not run: " * first_line(out),
        "That message comes from $name itself, not from this check. " *
        "Resolve it, then run this check again.")
end

# A check result: status is :ok, :fail, or :unknown.
struct Result
    status::Symbol
    title::String
    detail::String
    fix::String
end

ok(t, d)      = Result(:ok, t, d, "")
fail(t, d, f) = Result(:fail, t, d, f)
unknown(t, d, f) = Result(:unknown, t, d, f)

# ------------------------------------------------------------------ checks

function check_julia_version()
    t = "Julia version"
    if VERSION == PIN
        return ok(t, "$VERSION (matches the Fall 2026 pin)")
    end
    return fail(t, "running $VERSION, but this course is pinned to $PIN",
        "Run `juliaup add $PIN`, then start Julia with `julia +$PIN`, or set " *
        "the workspace pin (check 9) so VS Code always uses it.")
end

function check_juliaup()
    t = "juliaup"
    okc, out = probe(["juliaup", "--version"])
    if !okc
        d, f = probe_failure("juliaup", out,
            "Julia may have been installed directly rather than through " *
            "juliaup. Install juliaup, then `juliaup add $PIN`.")
        return fail(t, d, f)
    end
    version_line = first_line(out)
    oks, status = probe(["juliaup", "status"])
    if !oks
        return unknown(t, "$version_line is installed, but `juliaup status` failed",
            "Run `juliaup status` by hand and read the error.")
    end
    if occursin(string(PIN), status)
        return ok(t, "$version_line, and $PIN is installed")
    end
    return fail(t, "$version_line is installed, but $PIN is not among its versions",
        "Run `juliaup add $PIN`.")
end

function check_git()
    t = "Git"
    okc, out = probe(["git", "--version"])
    if !okc
        d, f = probe_failure("git", out,
            "Install Git, then open a NEW terminal so the PATH is picked up.")
        return fail(t, d, f)
    end
    return ok(t, first_line(out))
end

function check_claude_cli()
    t = "Claude Code (command line)"
    okc, out = probe(["claude", "--version"])
    if !okc
        d, f = probe_failure("claude", out,
            "The Claude desktop app does not provide this command; the " *
            "command line tool is a separate install. Install it, then open " *
            "a NEW terminal.")
        return fail(t, d, f)
    end
    return ok(t, first_line(out))
end

function check_code_cli()
    t = "VS Code (`code` command)"
    okc, out = probe([CODE_CMD, "--version"])
    if !okc
        d, f = probe_failure(CODE_CMD, out,
            Sys.isapple() ?
                "In VS Code run Shell Command: Install 'code' command in PATH " *
                "from the Command Palette, then open a new terminal." :
                "Install VS Code, then open a NEW terminal so the PATH is picked up.")
        return fail(t, d, f)
    end
    return ok(t, "version " * first_line(out))
end

"""Both extension checks share one `code --list-extensions` call."""
function extension_list()
    okc, out = probe([CODE_CMD, "--list-extensions"])
    okc || return nothing
    return Set(strip.(lowercase.(split(out, '\n'))))
end

function check_extension(exts, id, t)
    exts === nothing && return unknown(t,
        "could not list VS Code extensions, because the `code` command did not run",
        "Fix the `code` command first; this check depends on it.")
    lowercase(id) in exts && return ok(t, "$id is installed")
    return fail(t, "$id is not installed",
        "Run `code --install-extension $id`.")
end

function check_materials()
    t = "Course materials"
    isdir(MATERIALS) || return fail(t, "no materials folder at $MATERIALS",
        "Clone https://github.com/$REPO_SLUG into a folder named `materials`.")
    okc, out = probe(["git", "-C", MATERIALS, "remote", "get-url", "origin"])
    okc || return unknown(t,
        "$MATERIALS exists, but its Git remote could not be read",
        "It may not be a Git clone. Re-clone it rather than copying the files.")
    url = first_line(out)
    occursin(REPO_SLUG, url) || return fail(t,
        "the materials folder points at $url, not $REPO_SLUG",
        "Re-clone from https://github.com/$REPO_SLUG.")
    return ok(t, "cloned from $REPO_SLUG")
end

function check_workspace_pin()
    t = "Workspace Julia pin"
    settings = joinpath(ROOT, ".vscode", "settings.json")
    isfile(settings) || return fail(t, "no $settings",
        "This file is what makes VS Code use Julia $PIN for the course " *
        "without changing your global default. Copy it from " *
        "materials/env/vscode-settings.json.")
    text = read(settings, String)
    occursin("julia.executablePath", text) || return fail(t,
        "$settings does not set julia.executablePath",
        "Copy materials/env/vscode-settings.json over it.")
    occursin(string(PIN), text) || return fail(t,
        "$settings sets julia.executablePath, but does not name $PIN",
        "The course pin is $PIN. Copy materials/env/vscode-settings.json over it.")
    occursin("julia.useCodeLens", text) || return fail(t,
        "$settings predates the cell-execution fix",
        "Without julia.useCodeLens, the Run button above a cell runs whichever " *
        "cell the cursor is in. Copy materials/env/vscode-settings.json over it.")
    return ok(t, "VS Code is pinned to Julia $PIN for this folder")
end

function check_environment_files()
    t = "Environment files"
    proj = joinpath(ENV_DIR, "Project.toml")
    man  = joinpath(ENV_DIR, "Manifest.toml")
    isfile(proj) || return fail(t, "missing $proj", "Re-clone the materials.")
    isfile(man)  || return fail(t, "missing $man",  "Re-clone the materials.")
    local recorded
    try
        recorded = get(TOML.parsefile(man), "julia_version", nothing)
    catch e
        return unknown(t, "Manifest.toml could not be parsed ($(typeof(e)))",
            "Re-clone the materials; the file may be truncated.")
    end
    recorded === nothing && return unknown(t,
        "Manifest.toml records no julia_version",
        "Re-clone the materials.")
    recorded == string(PIN) || return fail(t,
        "Manifest.toml was built with Julia $recorded, but the pin is $PIN",
        "These must agree. Report this, rather than editing the file.")
    return ok(t, "Project.toml and Manifest.toml present, built with Julia $recorded")
end

function check_packages()
    t = "Course packages load"
    proj = joinpath(ENV_DIR, "Project.toml")
    isfile(proj) || return unknown(t,
        "skipped, because the environment files are missing",
        "Fix check 10 first.")
    local names
    try
        names = sort(collect(keys(get(TOML.parsefile(proj), "deps", Dict()))))
    catch
        return unknown(t, "Project.toml could not be parsed", "Fix check 10 first.")
    end
    try
        Pkg.activate(ENV_DIR; io = devnull)
    catch e
        return fail(t, "the environment could not be activated ($(typeof(e)))",
            "Run `using Pkg; Pkg.activate(\"$(escape_string(ENV_DIR))\"); Pkg.instantiate()`.")
    end
    failed = String[]
    for n in names
        try
            Base.eval(Main, Meta.parse("using $n"))
        catch
            push!(failed, n)
        end
    end
    isempty(failed) && return ok(t, "all $(length(names)) packages loaded")
    return fail(t, "these did not load: " * join(failed, ", "),
        "Run `using Pkg; Pkg.activate(\"$(escape_string(ENV_DIR))\"); Pkg.instantiate()`. " *
        "Do NOT run Pkg.update(); it would move you off the pinned versions.")
end

# ------------------------------------------------------------------ report

function main()
    # Progress notes go straight to the terminal. The report itself is built in
    # a buffer so this script can write the file in UTF-8 on its own, rather
    # than relying on the shell to do it. A Windows console pipeline mangles
    # both the encoding and any non-ASCII character on the way to disk, and the
    # file a student pastes into Moodle has to be exactly what was printed.
    println("Running the ISE 754 bootstrap check.")
    println("Loading the course packages takes a few minutes the first time.")
    println()

    exts = extension_list()

    results = [
        check_julia_version(),
        check_juliaup(),
        check_git(),
        check_claude_cli(),
        check_code_cli(),
        check_extension(exts, JULIA_EXT,  "Julia VS Code extension"),
        check_extension(exts, CLAUDE_EXT, "Claude Code VS Code extension"),
        check_materials(),
        check_workspace_pin(),
        check_environment_files(),
        check_packages(),
    ]

    io = IOBuffer()
    println(io, "ISE 754 - Fall 2026 bootstrap check")
    println(io, "="^70)
    println(io, "Machine  : ", Sys.MACHINE)
    println(io, "OS       : ", Sys.iswindows() ? "Windows" :
                              Sys.isapple()   ? "macOS"   :
                              "Linux (NOT a supported platform for ISE 754)")
    println(io, "Julia    : ", VERSION)
    println(io, "Folder   : ", ROOT)
    println(io)
    if !Sys.iswindows() && !Sys.isapple()
        println(io, "This course supports Windows and macOS. The checks below still run, but")
        println(io, "nothing here has been tested on this platform. Say so when you submit.")
        println(io)
    end

    for (i, r) in enumerate(results)
        mark = r.status === :ok ? "PASS" : r.status === :fail ? "FAIL" : "????"
        println(io, lpad(i, 2), ". [", mark, "] ", r.title, " - ", r.detail)
    end

    trouble = [(i, r) for (i, r) in enumerate(results) if r.status !== :ok]
    println(io)
    println(io, "="^70)

    if isempty(trouble)
        println(io, "READY")
        println(io)
        println(io, "All eleven checks passed. Paste this entire output into Moodle.")
    else
        nfail = count(r -> r.status === :fail, results)
        nunk  = count(r -> r.status === :unknown, results)
        println(io, "NOT READY - $nfail failed, $nunk could not be determined.")
        println(io)
        println(io, "What to do, in order:")
        for (i, r) in trouble
            println(io)
            println(io, "  Check $i - ", r.title)
            println(io, "    Problem: ", r.detail)
            println(io, "    Fix    : ", r.fix)
        end
        println(io)
        println(io, "Ask Claude Code to fix one item, quoting the line above, then run")
        println(io, "this check again. Paste this entire output into Moodle either way;")
        println(io, "an honest NOT READY before class is the point of running it early.")
    end

    report = String(take!(io))
    print(report)

    outfile = joinpath(ROOT, "bootstrap-output.txt")
    try
        open(outfile, "w") do f
            write(f, report)
        end
        println("\nSaved to ", outfile, " - paste that file into Moodle.")
    catch e
        println("\nCould not write ", outfile, " ($(typeof(e))).")
        println("Copy the text above instead.")
    end

    return isempty(trouble) ? 0 : 1
    return 1
end

exit(main())
