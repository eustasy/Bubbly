---
name: version-option-lists
description: When listing version options in config files, list newest at the top and oldest at the bottom; include every version still receiving any form of support (security included); the newest version is always the default.
metadata:
  type: feedback
---

When editing lists of versioned options in this repo — currently the PHP socket options in `nginx-config/conf.d/php_sockets.conf`:

1. **Order descending** — newest version at the top, oldest at the bottom.
2. **Keep every still-supported version** — include versions still receiving security support, not only those in active support. Don't drop a version just because its active-support window has ended.
3. **The latest version is always the default** — the `[DEFAULT]` marker (and the uncommented `server`/active line) goes on the newest entry, which is the one at the top of the list.

**Why:**
- The repo's original ordering convention was descending. The user pushed back when an edit made it ascend (called it "inverted").
- The user separately corrected an edit that had dropped PHP 8.2, saying "8.2 shouldn't be gone yet" — i.e. while 8.2's active support has ended, security support still places it within the support envelope they care about.
- The user then corrected another edit that left an older version (8.3) marked `[DEFAULT]` while a newer supported version (8.5) was disabled, with the rule "the latest version should always be the default."

**How to apply:**
- Sort newest → oldest top-to-bottom every time.
- Cross-reference [PHP supported versions](https://www.php.net/supported-versions.php) (or equivalent project page) and include each version listed there, including those in security-only support. **Verify the dates rather than trusting the ones already in the file** — in August 2026 every "Supported until" date in `php_sockets.conf` was wrong, apparently active-support ends from a superseded schedule. PHP retires a branch at the end of a calendar year, so every date should be a 31 December, and active and security windows are worth stating separately.
- The newest entry is the default target. In `php_sockets.conf` that means the `php_sockets` upstream points at it, since every branch now has an upstream of its own rather than options being commented in and out.
