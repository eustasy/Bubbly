# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bubbly is a set of Nginx configuration templates plus three helper bash scripts that bootstrap Certbot/Let's Encrypt on a Linux server. There is no application code — only Nginx `.conf` files, a `mime.types` file, and shell scripts. Nothing here runs locally; everything is meant to be installed under `/etc/nginx/` on a real server.

## Deployment flow (the one path the README is teaching)

The README walks through a fixed six-step setup. The three scripts at the repo root each correspond to a step:

1. `bubbly_generate-statics.sh` — creates `/etc/nginx/ssl/ticket.key` (80-byte random) and `/etc/nginx/ssl/dhparam3.pem` (3072-bit DH params). Run once per server; takes a long time.
2. `bubbly_copy-configs.sh` — `rsync -avh "$SCRIPT_DIR/nginx-config/" /etc/nginx/`. The script resolves its own directory, so it works regardless of CWD. Re-running it is the way to roll out config changes.
3. `bubbly_renew-ssl.sh -d example.com -d www.example.com` — invokes `certbot certonly --authenticator webroot --webroot-path=/tmp/bubbly-authenticator …`. After issuance/renewal it `service nginx reload`s.

Verify-then-promote uses two site templates under `nginx-config/sites-available/`: `bubbly_verify.conf` (HTTP-only, just enough to satisfy ACME http-01) and `bubbly_live.conf` (the real HTTPS site with three server blocks: HTTP→HTTPS redirect, `www`→apex HTTPS redirect, and the apex HTTPS server). Operators copy a template to `example.com.conf`, search-and-replace `example.com` with their domain, symlink into `sites-enabled/`, and run `sudo nginx -t && sudo service nginx reload`.

## Config layout convention (matters for include paths)

`nginx-config/` mirrors `/etc/nginx/`. After `bubbly_copy-configs.sh`, every directory below appears at the same path under `/etc/nginx/`:

- `conf.d/` — files Nginx auto-includes at the `http` context (limit zones, log formats, expires-map, php upstream, stub-status servers).
- `directive/` — snippets meant to be `include`d inside a `server` or `location` block (gzip, SSL, security headers, logging variants, request-size limits).
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

`directive/bubbly_security-headers_csp.conf` builds the Content-Security-Policy across many `set $bubbly_csp "$bubbly_csp …";` lines so each policy directive stays on its own readable line, then emits one `add_header` per header name (`Content-Security-Policy`, `X-Content-Security-Policy`, `X-WebKit-CSP`) reusing the variable. If you extend the policy, append another `set` line — don't collapse it into a single quoted multi-line value (multi-line quoted strings produce a header value containing literal newlines, which is invalid HTTP).

## CI

Keep the matrix `php-version` array in sync with the option list in `nginx-config/conf.d/php_sockets.conf`.

## Repo conventions to honour when editing

- **Version-option lists are descending and include all still-supported versions, with the newest as `[DEFAULT]`.** Applies to `nginx-config/conf.d/php_sockets.conf` and the `php-version` matrix in `.github/workflows/normal.yml` — keep them in sync. Include security-supported versions, not only actively-developed ones.
- **Preserve multi-line, aligned formatting in config files** when fixing bugs. If a fix would force collapsing nice columns to a single line, find another way (e.g. `set` accumulators) or ask first.
- **Tabs**, not spaces, inside Nginx `.conf` files (the existing files are tab-indented).
- **`example.com`** is the placeholder domain used throughout `sites-available/` templates; the README tells operators to search-and-replace it.

## Useful commands

There is no build step. Useful commands when iterating:

```bash
# Validate Nginx config (only meaningful on a server with this installed):
sudo nginx -t && sudo service nginx reload
```
