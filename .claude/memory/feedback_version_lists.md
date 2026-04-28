---
name: version-option lists — descending order, include all supported, latest is default
description: When listing version options in config files, list newest at the top and oldest at the bottom; include every version still receiving any form of support (security included); the newest version is always the default.
type: feedback
---

When editing lists of versioned options in this repo (e.g. PHP socket options in `nginx-config/conf.d/php_sockets.conf`, the PHP CI matrix in `.github/workflows/normal.yml`):

1. **Order descending** — newest version at the top, oldest at the bottom.
2. **Keep every still-supported version** — include versions still receiving security support, not only those in active support. Don't drop a version just because its active-support window has ended.
3. **The latest version is always the default** — the `[DEFAULT]` marker (and the uncommented `server`/active line) goes on the newest entry, which is the one at the top of the list.

**Why:**
- The repo's original ordering convention was descending. The user pushed back when an edit made it ascend (called it "inverted").
- The user separately corrected an edit that had dropped PHP 8.2, saying "8.2 shouldn't be gone yet" — i.e. while 8.2's active support has ended, security support still places it within the support envelope they care about.
- The user then corrected another edit that left an older version (8.3) marked `[DEFAULT]` while a newer supported version (8.5) was disabled, with the rule "the latest version should always be the default."

**How to apply:**
- Sort newest → oldest top-to-bottom every time.
- Cross-reference [PHP supported versions](https://www.php.net/supported-versions.php) (or equivalent project page) and include each version listed there, including those in security-only support.
- Mark the top (newest) entry as `[DEFAULT]` and leave its `server`/active line uncommented; mark every older entry as `[DISABLED]` with the line commented out. Any backup-socket reference should also point at the latest version.
- Keep `php_sockets.conf` and the workflow matrix in `.github/workflows/normal.yml` in sync.
