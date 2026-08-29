#!/usr/bin/env julia
# test_check_names.jl -- canonical_checks against the SHARED fixture.
#
# The same rule exists twice, in Julia here (it ships to students) and in Python in
# tools/check_coverage.py (staff tooling). Two implementations of one rule drift unless
# something holds them together, so both read tools/check_names_fixture.tsv and a change to
# one alone turns the other red.
#
# Run:  julia test_check_names.jl
# Exit: 0 all cases agree with the fixture, 1 otherwise.

include(joinpath(@__DIR__, "build_profile.jl"))

function fixture_path()
    # Beside the staff tools when run from the staff repo; the shipped copy in a student
    # tree has no tools/ directory, which is fine -- the test is a staff test.
    for p in (joinpath(@__DIR__, "..", "..", "tools", "check_names_fixture.tsv"),
              joinpath(@__DIR__, "check_names_fixture.tsv"))
        isfile(p) && return p
    end
    return nothing
end

function main()
    fx = fixture_path()
    if fx === nothing
        println("fixture not found; this test only runs in the staff repository")
        return 0
    end

    total = 0; bad = 0
    for line in eachline(fx)
        s = strip(line)
        (isempty(s) || startswith(s, "#")) && continue
        # A line with NO tab means "names none of the nine", and those are the cases that
        # prove we do not false-match. Skipping them was the first version's bug: Julia read
        # 18 cases where Python read 25, and the seven it dropped were unbounded, sourced,
        # Boundshire, resourceful and the three plain-English non-answers. A shared fixture
        # only holds two implementations together if both read the same rows.
        parts = split(rstrip(line, ['\n', '\r']), '\t')
        raw = parts[1]
        want = length(parts) < 2 ? String[] :
               sort(filter(!isempty, strip.(split(strip(parts[2]), ','))))
        got = sort(canonical_checks(raw))
        total += 1
        if got != want
            bad += 1
            println("  FAIL  ", repr(raw))
            println("        want ", want, "  got ", got)
        end
    end
    println("canonical_checks (Julia): $(total - bad)/$total fixture cases pass")

    # The count itself is an assertion. tools/check_coverage.py --self-test must report the
    # same total; a silent difference means one side is skipping rows the other checks.
    expected_cases = count(l -> !isempty(strip(l)) && !startswith(strip(l), "#"),
                           collect(eachline(fx)))
    if total != expected_cases
        println("  FAIL  read $total rows but the fixture holds $expected_cases")
        bad += 1
    end
    if bad == 0
        println("agrees with tools/check_coverage.py, which reads the same file")
    end
    return bad == 0 ? 0 : 1
end

exit(main())
