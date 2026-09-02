# lectures

Companion scripts land here as each lecture is published, one per lecture,
with any data it reads in a `data/` folder beside it.

The set grows through the semester, so a script you do not see yet belongs to
a lecture that is not published yet. Not every lecture has one: 1.1 is the
install charge and carries no Julia, so it has no script.

Each script opens with a `## Get class-ready` cell that finds the course
environment in `../env/` and installs every package at its pinned version.
Run that cell once when you open a script; it is safe to run again.

## The `.md` files

Beside each published lecture's script is a `.md` file with the same name.
It is a plain-text copy of that lecture, and it is here for Claude to read
rather than for anyone to read directly. A lecture's web page is several
megabytes, most of it fonts and styling carried inside the file, so a
session that tries to fetch the page gets a fragment of it and cannot tell
that anything is missing. The `.md` copy is a fraction of the size and
holds the whole lecture, so a review or homework session actually starts
from the material instead of from what the model already believes.

It is generated from the published page, not from the source, so every
number in it is the number the page shows. Reading the lecture on the web
is still the better experience for a person: the figures, the formatting
and the navigation are all there and none of them survive into the text
copy. There is nothing to edit here — these files are rebuilt from the
page whenever a lecture changes, and an edit would be overwritten.
