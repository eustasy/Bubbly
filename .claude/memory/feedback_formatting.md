---
name: keep nice formatting in config files
description: When fixing bugs in config/source files, preserve the user's existing multi-line layout, alignment, and indentation rather than collapsing to single lines.
type: feedback
---

When fixing bugs in nginx (or similar) config files, do not collapse multi-line, nicely-aligned values to a single line just because that's the simplest fix.

**Why:** The user explicitly pushed back on a CSP fix that flattened a multi-line `add_header` value into one long line. They value the readability of the original layout.

**How to apply:** Find a fix that preserves the original formatting — e.g. for nginx, use `set $var "...";` accumulators across lines and reference the variable in `add_header`, or otherwise structure the change so the file still reads cleanly. If a fix genuinely requires a single line, call that out and ask before doing it.
