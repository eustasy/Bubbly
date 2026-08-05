---
name: open-follow-ups
description: Small known issues in the shipped config that were noticed and deliberately left, plus the missing CHANGELOG for v3's breaking changes.
metadata:
  type: project
---

Judgements, not defects — each was seen, weighed and left alone. Worth knowing before someone rediscovers them as bugs.

- **Two `Cache-Control` headers.** A response from a site including both groups carries `no-cache` from `expires` and `no-transform` from `directive/h5bp_no-transform.conf`. Valid HTTP, since clients merge them, but surprising when debugging caching.
- **`default 1y` in the expires map catches `text/plain`**, so `robots.txt`, `security.txt` and `ads.txt` get a year — and those are exactly the files occasionally needing a hurried change. Worth revisiting whenever the map is next touched.
- **`limit_conn conPerServer 2000` can be unreachable.** A connection cap only bites if `worker_processes × worker_connections` exceeds it, and Debian and Ubuntu set `worker_connections 768`, so it does nothing below three cores. Stated in the file.
- **No CHANGELOG.** v3 carries several breaking changes with only commit messages recording them: the platform floor, the TLS profile moving to a server-level include, `expires` no longer applying server-wide, deleted limit zones (`reqPerSec1/10`, `siteReqPerSec1/10`), renamed zones and limits files, and the ACME webroot moving out of `/tmp`.
- **The doc-link CI check cannot see org-inherited files.** It resolves `Bubbly/blob/<ref>/<path>` links against the working tree, so the `?tab=coc-ov-file` and `?tab=security-ov-file` links are verified only by hand. See the community-health note in CLAUDE.md.
