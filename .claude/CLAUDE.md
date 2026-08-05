# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bubbly is a set of Nginx configuration templates plus three helper bash scripts that bootstrap Certbot/Let's Encrypt on a Linux server. There is no application code — only Nginx `.conf` files, a `mime.types` file, and shell scripts. Nothing here runs locally; everything is meant to be installed under `/etc/nginx/` on a real server.

## Deployment flow (the one path the README is teaching)

The README opens with Requirements and PHP notes, then walks through a six-step install and an optional section. Two of the three scripts at the repo root are steps in that walkthrough; the third is the optional one:

1. `bubbly_copy-configs.sh` — `rsync -avh "$SCRIPT_DIR/nginx-config/" /etc/nginx/`. The script resolves its own directory, so it works regardless of CWD. Re-running it is the way to roll out config changes.
2. `bubbly_renew-ssl.sh -d example.com -d www.example.com` — invokes `certbot certonly --authenticator webroot --webroot-path=/var/lib/bubbly-authenticator …`. After issuance/renewal it `service nginx reload`s.
3. `bubbly_generate-tickets.sh` — creates `/etc/nginx/ssl/ticket.key` (80-byte random). **Optional**, and no longer part of the main flow: Nginx 1.23.2+ generates and rotates ticket keys itself in the shared session cache. Only needed when several Nginx instances behind a load balancer must resume each other's tickets, and then `ssl_session_ticket_key` has to be uncommented in `conf.d/bubbly_ssl.conf`.

Three site templates live under `nginx-config/sites-available/`. `bubbly_default.conf` is the catch-all default server, symlinked once per server, which answers unmatched Host headers and no-SNI connections; the distribution's own `sites-enabled/default` must be removed first or Nginx refuses to start with "a duplicate default server". Then verify-then-promote uses `bubbly_http.conf` (HTTP handler: ACME passthrough + redirect to HTTPS, kept active permanently) and `bubbly_https.conf` (the real HTTPS site: `www`→apex redirect and apex HTTPS server). Operators copy each template to `example.com_http.conf` / `example.com_https.conf`, search-and-replace `example.com` with their domain, symlink both into `sites-enabled/`, and run `sudo nginx -t && sudo service nginx reload`.

## Config layout convention (matters for include paths)

`nginx-config/` mirrors `/etc/nginx/`. After `bubbly_copy-configs.sh`, every directory below appears at the same path under `/etc/nginx/`:

- `conf.d/` — files Nginx auto-includes at the `http` context (socket-wide TLS in `bubbly_ssl.conf`, limit zones, expires-map, php upstream).
- `directive/` — snippets meant to be `include`d inside a `server` or `location` block (the TLS profile and stapling, gzip and Brotli, security headers, logging variants, rate-limit variants, real-ip, request-size limits).
- `location/` — full `location { … }` blocks ready to be `include`d inside `server`.
- `groups/` — bundles that `include` several `directive/`/`location/` files at once (`security-common.conf`, `performance-common.conf`).
- `sites-available/` — site templates. Operator symlinks chosen ones into `/etc/nginx/sites-enabled/`.

**Include paths inside config files are relative to `/etc/nginx/`** (e.g. `include directive/bubbly_logs_off.conf;`). They only resolve after deploy — there is no way to `nginx -t` against the in-tree files. Editing must therefore be careful: a typo in an include path won't fail until the operator runs `nginx -t` on the server.

`mime.types` lives at the repo root of `nginx-config/` and replaces the distro's default.

## Marker conventions in `.conf` files

Search-driven configurability. Comments use three uppercase tags consistently — preserve these when editing:

- `# [OPTION]` — a knob the operator should consider; usually followed by 2–4 alternatives where one is uncommented.
- `# [DEFAULT]` — marks which option is the active/uncommented choice.
- `# [WARNING]` — preconditions, breakage notes, or rate-limit/security caveats.

The README tells operators to grep for these. Don't quietly drop or rephrase the markers when refactoring.

## CSP / security-headers structure

`directive/bubbly_security-headers_csp.conf` builds the Content-Security-Policy across many `set $bubbly_csp "$bubbly_csp …";` lines so each policy directive stays on its own readable line, then emits a single `add_header Content-Security-Policy $bubbly_csp always;`. If you extend the policy, append another `set` line — don't collapse it into a single quoted multi-line value (multi-line quoted strings produce a header value containing literal newlines, which is invalid HTTP).

## Community health files live in the org, not here

`CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, the issue forms and the pull request template all come from [eustasy/.github](https://github.com/eustasy/.github) and are inherited by every eustasy repository. They are genuinely absent from this repo and genuinely in force — don't treat a reference to them as a broken link and delete it. Link them repo-scoped: `https://github.com/eustasy/Bubbly?tab=coc-ov-file`, `?tab=security-ov-file`.

## Supported platforms (version floor)

Bubbly 3.x targets **Ubuntu 26.04 LTS** — in practice **Nginx 1.25.1+** (for the `http2` directive) and **OpenSSL 3.5+** (for `X25519MLKEM768` in `ssl_ecdh_curve`). Ubuntu 24.04, Ubuntu 22.04 and Debian 12 fail both gates and are out of support for 3.x; the README points those operators at the `2.2.0` tag. Debian 13 qualifies on Nginx 1.26, making it the *lowest* supported Nginx.

Don't add fallback spellings or `[OPTION]` pairs for pre-floor versions. Where a directive needs something newer than a still-common distro provides, mark it `# [WARNING]` naming the minimum and the older equivalent — as done for `http2 on;` in `sites-available/bubbly_https.conf` and `ssl_ecdh_curve` in `directive/bubbly_ssl-profile.conf`. The README's Requirements section is the operator-facing version of this; keep the two in sync.

PHP versions are co-installable out of the box — Debian and Ubuntu version the packages throughout (`/etc/php/8.5/`, `php8.4-fpm.service`, `/run/php/php8.4-fpm.sock`), so nothing special is needed to run several at once. Each release only _carries_ one, though: Ubuntu 26.04 has 8.5 (matching the `[DEFAULT]` in `php_sockets.conf`), Ubuntu 24.04 has 8.3, Debian 13 has 8.4. Extra versions come from Ondřej Surý's packages (`ppa:ondrej/php`, or packages.sury.org/php on Ubuntu 26.04 and Debian).

## CI

`.github/workflows/nginx.yml` is the substantive one, with three jobs:

- `nginx-t` — a container matrix over `ubuntu:26.04` and `debian:13`, installing each distribution's own Nginx and leaving its `nginx.conf` untouched, since that is the layout Bubbly assumes. It deploys using the real `bubbly_copy-configs.sh`, runs `nginx -t` on the templates as shipped, adds two more sites the way the README instructs, then starts Nginx and probes it: SNI certificate selection, unmatched SNI and `Host` refused by the default server, ACME passthrough serving a token, per-site PHP upstream selection, rate-limit isolation, Brotli and gzip both negotiating, and the three per-vhost TLS behaviours.
- `repo-checks` — no container. Guards duplicated values against drift: `gzip_types` against `brotli_types`, the ACME webroot in `bubbly_renew-ssl.sh` against `location/bubbly_well-known-passthrough.conf`, every `bubbly_*.sh` executable, and every Markdown repo link resolving to a file that exists, with none naming `master`.
- `php-socket-path` — compares the `[DEFAULT]` socket in `php_sockets.conf` against the platform's real FPM pool, by basename.

There is deliberately **no PHP version matrix**: uncommenting each option and running `nginx -t` proves nothing, because the socket path parses identically whatever the version. `php-socket-path` tests the invariant that actually matters instead.

Container jobs default to `sh -e`, so the workflow pins `shell: bash`. That brings `-o pipefail`, under which `grep -q` closing a pipe early kills the writer and fails the pipeline — write output to a file and grep the file. After pushing, find a run by `headSha`; `gh run list --limit 1` races GitHub's run creation and returns the previous commit's.

## Decisions not to reverse without a reason

- **Distribution packages only, no third-party repositories.** 26.04's Nginx clears both gates, and it is the only route to Brotli: nginx.org's packages ship none, and the module packages are built against one exact Nginx ABI.
- **`fastcgi_pass php_sockets;` is the default**, with `$bubbly_php` as opt-in Option 2. A literal upstream resolves at config load, so a typo fails `nginx -t`; a variable resolves per request, so the same mistake becomes a 502. It also keeps upgrades safe, since our location file is replaced but an operator's site files are not, and those carry no `set`.
- **`--force-renew` stays** in `bubbly_renew-ssl.sh`. The systemd timer Certbot installs owns routine renewal, so a manual run means "issue now".
- **The session ticket key ships commented out.** 1.23.2+ generates and rotates its own in the shared session cache; an explicit key is only for several instances behind a load balancer resuming each other's tickets.
- **Brotli stays opt-in.** Without the module package, `brotli on;` stops Nginx loading any config at all — every site, not just the one that wanted it.
- **No `nginx:mainline` CI job.** It would need a hand-written `nginx.conf`, and a mainline warning is not actionable at LTS pace. The next Ubuntu *interim* release is the better canary, from 26.10 onwards.
- **Rate limits never apply to a `return` response**, because `return` is handled in the rewrite phase and limits in preaccess. The HTTP-to-HTTPS redirect therefore cannot be rate limited at all; put limits where content is actually served.

## Repo conventions to honour when editing

- **Version-option lists are descending and include all still-supported versions, with the newest as `[DEFAULT]`.** Applies to `nginx-config/conf.d/php_sockets.conf`. Include security-supported versions, not only actively-developed ones, and verify the dates against php.net rather than trusting the ones already in the file.
- **Preserve multi-line, aligned formatting in config files** when fixing bugs. If a fix would force collapsing nice columns to a single line, find another way (e.g. `set` accumulators) or ask first.
- **Tabs**, not spaces, inside Nginx `.conf` files (the existing files are tab-indented).
- **`example.com`** is the placeholder domain used throughout `sites-available/` templates; the README tells operators to search-and-replace it.
- **Rate and connection limits stay opt-in — never add a limits include to `groups/`.** Decided 2026-08-05. Whether a given rate is safe depends on two things Bubbly cannot know: whether Nginx is behind a proxy or CDN, which collapses every address-keyed zone into one bucket for the whole audience, and whether clients speak HTTP/2, which turns a page load from dozens of connections into one. The recommended placement is inside `location ~ \.php$` so only expensive requests are counted; see `conf.d/bubbly_limits.conf`.
- **Markdown emphasis is `_italic_` with underscores and `**bold**` with asterisks**, pinned as MD049/MD050 in `.qlty/configs/.markdownlint.json`. Mixing styles fails `md.yml`, and the formatter and linter disagree if the rule is left on its "consistent" default.
- **The TLS profile lives in `directive/bubbly_ssl-profile.conf` and is included from a `server` block — never at the `http` level.** Debian and Ubuntu set `ssl_protocols`, `ssl_prefer_server_ciphers` and `keepalive_timeout` in their own `nginx.conf`, and repeating any of those in `conf.d/` is a fatal "directive is duplicate". Only settings the distribution does not touch (the session cache, the resolver) may go in `conf.d/bubbly_ssl.conf`.
- **`ssl_protocols` and `ssl_ecdh_curve` only take effect from the default server** for a listening socket, because the handshake starts before SNI selects a server — measured on Nginx 1.26 and 1.28. That is why `bubbly_default.conf` includes the profile, and why sites include it too as a safety net. `ssl_ciphers` is the one exception and may be overridden per server, for TLS 1.2 only, as long as the override sits after the profile include. CI asserts all three behaviours, so a regression fails the build rather than silently invalidating the design.

## Useful commands

There is no build step. Useful commands when iterating:

```bash
# Validate Nginx config (only meaningful on a server with this installed):
sudo nginx -t && sudo service nginx reload
```
