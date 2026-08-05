# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bubbly is a set of Nginx configuration templates plus three helper bash scripts that bootstrap Certbot/Let's Encrypt on a Linux server. There is no application code — only Nginx `.conf` files, a `mime.types` file, and shell scripts. Nothing here runs locally; everything is meant to be installed under `/etc/nginx/` on a real server.

## Deployment flow (the one path the README is teaching)

The README walks through a fixed six-step setup. The three scripts at the repo root each correspond to a step:

1. `bubbly_copy-configs.sh` — `rsync -avh "$SCRIPT_DIR/nginx-config/" /etc/nginx/`. The script resolves its own directory, so it works regardless of CWD. Re-running it is the way to roll out config changes.
2. `bubbly_renew-ssl.sh -d example.com -d www.example.com` — invokes `certbot certonly --authenticator webroot --webroot-path=/tmp/bubbly-authenticator …`. After issuance/renewal it `service nginx reload`s.
3. `bubbly_generate-tickets.sh` — creates `/etc/nginx/ssl/ticket.key` (80-byte random). **Optional**, and no longer part of the main flow: Nginx 1.23.2+ generates and rotates ticket keys itself in the shared session cache. Only needed when several Nginx instances behind a load balancer must resume each other's tickets, and then `ssl_session_ticket_key` has to be uncommented in `conf.d/bubbly_ssl.conf`.

Three site templates live under `nginx-config/sites-available/`. `bubbly_default.conf` is the catch-all default server, symlinked once per server, which answers unmatched Host headers and no-SNI connections; the distribution's own `sites-enabled/default` must be removed first or Nginx refuses to start with "a duplicate default server". Then verify-then-promote uses `bubbly_http.conf` (HTTP handler: ACME passthrough + redirect to HTTPS, kept active permanently) and `bubbly_https.conf` (the real HTTPS site: `www`→apex redirect and apex HTTPS server). Operators copy each template to `example.com_http.conf` / `example.com_https.conf`, search-and-replace `example.com` with their domain, symlink both into `sites-enabled/`, and run `sudo nginx -t && sudo service nginx reload`.

## Config layout convention (matters for include paths)

`nginx-config/` mirrors `/etc/nginx/`. After `bubbly_copy-configs.sh`, every directory below appears at the same path under `/etc/nginx/`:

- `conf.d/` — files Nginx auto-includes at the `http` context (socket-wide TLS in `bubbly_ssl.conf`, limit zones, expires-map, php upstream).
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

`directive/bubbly_security-headers_csp.conf` builds the Content-Security-Policy across many `set $bubbly_csp "$bubbly_csp …";` lines so each policy directive stays on its own readable line, then emits a single `add_header Content-Security-Policy $bubbly_csp always;`. If you extend the policy, append another `set` line — don't collapse it into a single quoted multi-line value (multi-line quoted strings produce a header value containing literal newlines, which is invalid HTTP).

## Supported platforms (version floor)

Bubbly 3.x targets **Ubuntu 26.04 LTS** — in practice **Nginx 1.25.1+** (for the `http2` directive) and **OpenSSL 3.5+** (for `X25519MLKEM768` in `ssl_ecdh_curve`). Ubuntu 24.04, Ubuntu 22.04 and Debian 12 fail both gates and are out of support for 3.x; the README points those operators at the `2.2.0` tag. Debian 13 qualifies on Nginx 1.26, making it the *lowest* supported Nginx.

Don't add fallback spellings or `[OPTION]` pairs for pre-floor versions. Where a directive needs something newer than a still-common distro provides, mark it `# [WARNING]` naming the minimum and the older equivalent — as done for `http2 on;` in `sites-available/bubbly_https.conf` and `ssl_ecdh_curve` in `directive/bubbly_rock-hard-ssl.conf`. The README's Requirements section is the operator-facing version of this; keep the two in sync.

PHP versions are co-installable out of the box — Debian and Ubuntu version the packages throughout (`/etc/php/8.5/`, `php8.4-fpm.service`, `/run/php/php8.4-fpm.sock`), so nothing special is needed to run several at once. Each release only *carries* one, though: Ubuntu 26.04 has 8.5 (matching the `[DEFAULT]` in `php_sockets.conf`), Ubuntu 24.04 has 8.3, Debian 13 has 8.4. Extra versions come from Ondřej Surý's packages (`ppa:ondrej/php`, or packages.sury.org/php on Ubuntu 26.04 and Debian).

## CI

`.github/workflows/nginx.yml` installs Nginx mainline from nginx.org, rsyncs `nginx-config/` into `/etc/nginx/`, generates a self-signed cert plus a session ticket key, symlinks both site templates and runs `nginx -t`.

There is currently **no** PHP version matrix in any workflow — the `.github/workflows/normal.yml` that older notes refer to no longer exists. If you restore one, keep its `php-version` array in sync with the option list in `nginx-config/conf.d/php_sockets.conf`.

## Repo conventions to honour when editing

- **Version-option lists are descending and include all still-supported versions, with the newest as `[DEFAULT]`.** Applies to `nginx-config/conf.d/php_sockets.conf`, and to any PHP matrix restored in CI (see above) — keep them in sync. Include security-supported versions, not only actively-developed ones.
- **Preserve multi-line, aligned formatting in config files** when fixing bugs. If a fix would force collapsing nice columns to a single line, find another way (e.g. `set` accumulators) or ask first.
- **Tabs**, not spaces, inside Nginx `.conf` files (the existing files are tab-indented).
- **`example.com`** is the placeholder domain used throughout `sites-available/` templates; the README tells operators to search-and-replace it.
- **TLS settings that cannot vary per site belong in `conf.d/bubbly_ssl.conf`, never in a site file or a `directive/` include.** Measured on Nginx 1.26 and 1.28: `ssl_protocols` and `ssl_ecdh_curve` are always taken from the default server for the listening socket, because the handshake starts before SNI selects a server. `ssl_ciphers` is the one exception and may be overridden per server, for TLS 1.2 only. CI asserts all three behaviours, so a regression there fails the build rather than silently invalidating the split.

## Useful commands

There is no build step. Useful commands when iterating:

```bash
# Validate Nginx config (only meaningful on a server with this installed):
sudo nginx -t && sudo service nginx reload
```
