# What is new, per skill version

Read by `update_course.jl` and printed to the student when a skill is reinstalled. Written
for the person about to use the skill, not for whoever merges the change.

**Format.** One `## <skill> <version>` heading, then one or two plain sentences. No markdown
inside the body, because it is printed to a terminal. A version with no entry prints nothing,
which is the right outcome for a typo fix.

**Keep it to what changes what they do.** "Asks a third closing question" earns a line. "Moved
the source directory" does not: it changes nothing a student does.

## review 6
Asks why you picked the check you picked, and records your answer in your own words. Tells
you at the start that you can stop and ask anything, with two example questions about the
lecture so you can see the shape of one, and asks again after the first example whether
anything is worth going deeper on.

## review 5
Ends by asking what you would change about the review itself. Two earlier questions were added
too: what is still unclear to you, and what you want covered in class.

## submit 2
Updates the course before it submits, so a stale copy of the command can no longer persist if
you run it directly rather than from /review or /homework.

## homework 1
First release. Fetches the published sheet, checks the mechanics a submission has to pass, and
copies the cumulative formula sheet in beside it when one is published.
