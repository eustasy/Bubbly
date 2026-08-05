---
name: multisite-refactor-plan
description: Agreed plan (2026-08-05, in progress) for making Bubbly v3 work on a server hosting several sites on different PHP versions and TLS profiles, at the Ubuntu 26.04 floor.
metadata:
  type: project
---

Plan agreed 2026-08-05 after auditing the config for "several sites, several PHP versions, different ciphers, one server". Per-item progress is in the Status line below; each completed item carries an "as built" note where the result differed from the plan. All work must respect [[nginx-version-floor]], the tab indentation and aligned-column conventions in [[feedback_formatting]], and the `[OPTION]`/`[DEFAULT]`/`[WARNING]` marker idiom.

**Status:** A, B, C, D, E and G are **done** and pushed (2026-08-05), CI green on both platforms. When checking a run after pushing, select it by `headSha` — `gh run list --limit 1` races GitHub's run creation and returns the previous commit's run, which cost two wasted verification cycles here. F's ticket-key decision landed with C, since moving the key to the http level would have made a missing key file break every site; F's remaining work is script hardening. Remaining sequence: I → F's leftovers → H → docs.

## A. Declare the floor — done 2026-08-05

Revised 2026-08-05 when the floor moved to Ubuntu 26.04 (see [[nginx-version-floor]]). `http2 on;` and the post-quantum `ssl_ecdh_curve` are both **correct as shipped** at this floor, so the original "restore 1.18 compatibility" work is void — no `[OPTION]` pairs, no fallback spellings. What remains is documentation and diagnosis:

- README: new Requirements section naming Ubuntu 26.04 LTS and Debian 13 as the supported platforms, nginx 1.25.1+ / OpenSSL 3.5+ as the real gates, with the verified version table and `nginx -v` / `openssl version` as the check. Point operators on Ubuntu 22.04, Ubuntu 24.04 or Debian 12 at the **2.2.0** tag — verified to use `listen 443 ssl http2;` and `ssl_ecdh_curve secp384r1;`, so it genuinely runs on those stacks.
- `sites-available/bubbly_https.conf`: `[WARNING]` beside `http2 on;` in both server blocks, naming the 1.25.1 minimum and the older `listen … ssl http2;` spelling, so an operator on an old box gets a diagnosis instead of `unknown directive`. A `[WARNING]`, not an `[OPTION]` — older platforms are out of support for v3.
- `directive/bubbly_rock-hard-ssl.conf`: same treatment for `ssl_ecdh_curve` — `[WARNING]` naming OpenSSL 3.5+ and the fallback of dropping `X25519MLKEM768` from the list.
- While in that file, convert lines 17-19 and 27-30 from 4-space to tab indentation. They are the only space-indented lines in any `.conf` (pasted from the Mozilla generator), and `.editorconfig:28-31` sets `indent_style = tab` for `nginx-config/**`.

## B. CI that can actually catch any of this

- **Verify first:** nginx.org's packaged `nginx.conf` includes only `conf.d/*.conf`, with no `sites-enabled` include (Debian's packaging adds that, nginx.org's does not). If so, the symlink step at `.github/workflows/nginx.yml:63-69` is inert and the site templates — plus every relative `include directive/…` path — have never been parsed by CI. Check with `grep -c sites-enabled /etc/nginx/nginx.conf`.
- Prefer the **distribution's own `nginx.conf`, untouched**, on the distro jobs. Debian and Ubuntu already include `modules-enabled/*.conf`, `conf.d/*.conf` and `sites-enabled/*`, which is precisely the layout Bubbly's `sites-available`/`sites-enabled` structure assumes — so testing against it needs no fixture and is the honest target. Only a non-distro build (nginx.org packages or the `nginx:*` Docker images) needs a hand-written `nginx.conf` fixture, because those include `conf.d/*.conf` alone.
- Matrix across the supported range, not just the newest end (the old workflow installed nginx.org mainline, so only the top was tested — and against the wrong layout). Two anchors, both distro packages per the packaging decision in [[nginx-version-floor]]: `ubuntu:26.04` + `apt-get install nginx` for the reference target (1.28.3 / OpenSSL 3.5.5) and `debian:13` for the **lowest supported nginx** (1.26.3 / OpenSSL 3.5.6). Docker containers rather than GHA runner images, so versions are pinned and explicit.
- **A `nginx:mainline` job was considered and dropped** (2026-08-05, user's call). It would need a hand-written `nginx.conf`, since those images include `conf.d/*.conf` only, and a mainline warning is not actionable for a project that moves at LTS pace. The forward-warning slot is better filled by the next Ubuntu **interim** release once it exists — same early signal, on the distro packaging path we actually support, no fixture required. Nothing to add until 26.10 ships in October 2026.
- Install `libnginx-mod-http-brotli-filter` in the Ubuntu 26.04 job once item I exists, so the Brotli directive file is actually parsed.
- Two-site fixture: `alpha.test` and `beta.test`, each with its own self-signed cert, one on PHP 8.5 and one on 8.3, with the new default-server file enabled. This is what surfaces duplicate `default_server`, mismatched session-cache sizes, and per-site upstream selection — none of which a single-site test can reach.
- Optional but valuable: start nginx and probe with `openssl s_client -servername` to measure which per-vhost SSL settings actually take effect. `ssl_protocols` provably comes from the default server; the behaviour of per-vhost `ssl_ciphers` is undocumented and better measured than guessed.
- **Decided against restoring a PHP version matrix.** Uncommenting each option in `php_sockets.conf` and running `nginx -t` proves nothing: `server unix:/var/run/php/php8.4-fpm.sock;` parses identically whatever the version, and nginx never checks that the socket exists. The invariant actually worth testing is that the `[DEFAULT]` option names the socket the reference platform's PHP-FPM really listens on — so the `php-socket-path` job compares the uncommented `server unix:…` line against `/etc/php/*/fpm/pool.d/www.conf`, by basename (Bubbly writes `/var/run/php/…`, the pool writes `/run/php/…`; same file via the `/var/run` symlink). The stale `normal.yml` references in CLAUDE.md and [[feedback_version_lists]] are already fixed.

### As built (2026-08-05)

`.github/workflows/nginx.yml` now runs two jobs. `nginx-t` is a container matrix over `ubuntu:26.04` and `debian:13` with `fail-fast: false`, installing each distribution's own nginx and leaving its `nginx.conf` untouched. It runs the real `bubbly_copy-configs.sh` and `bubbly_generate-tickets.sh` (so the scripts are exercised too), asserts `nginx.conf` includes `sites-enabled`, generates self-signed certs for `example.com`, `alpha.test` and `beta.test`, runs `nginx -t` with the templates as shipped, then adds the other two sites the way the README instructs (copy, `sed` the domain, symlink) and runs `nginx -t` again. Finally it dumps `nginx -T` and greps for each `server_name`, which is the guard against the config loading while the site files are silently ignored. `php-socket-path` is the socket-agreement job described above.

A third job, `scripts`, runs on the plain runner with no container and asserts every `bubbly_*.sh` is executable. This exists because `bubbly_generate-tickets.sh` was found at mode 100644 while the other two were 100755 — README step 2 tells operators to run it directly, so it failed with "Permission denied". Fixed with `git update-index --chmod=+x`. The `nginx-t` job only covers two of the three scripts incidentally by running them; `bubbly_renew-ssl.sh` would have to talk to Let's Encrypt, so its mode is otherwise unguarded.

### The runtime TLS probe (also built 2026-08-05)

Appended to `nginx-t`, so it runs on **both** nginx 1.26 and 1.28 — which also reveals whether the two versions behave alike. After the config assertions it writes a CI-only `directive/ci_beta-ssl.conf` (TLS 1.3 only, the single cipher `ECDHE-ECDSA-AES256-SHA384`, `prime256v1`, `ssl_prefer_server_ciphers on`), swaps beta.test's `include` to it, re-runs `nginx -t`, starts nginx and probes with `openssl s_client -brief`.

The design turns three questions into one measurement, because beta's values are all disjoint from the default server's:

- **No SNI at all** → reports which certificate answers, demonstrating the accidental default server. With no `default_server` anywhere, the winner is the alphabetically-first `sites-enabled` file, i.e. `alpha.test_https.conf`, whose first block is the `www` redirect.
- **TLS 1.2 to beta.test** → accepted means per-vhost `ssl_protocols` was ignored (confirming the docs); refused means it applied. If accepted, the negotiated cipher then says whether per-vhost `ssl_ciphers` applied: beta's lone CBC cipher versus the default server's GCM/ChaCha list.
- **TLS 1.3 to beta.test** → `prime256v1` means per-vhost `ssl_ecdh_curve` applied; `X25519MLKEM768` means the default server's list won.

Findings are emitted as `::notice::` annotations and **not asserted** — the answers are what item C needs, and converting them into assertions is C's job once the behaviour is known. Only the certain things are assertions: SNI serves the matching certificate for each of the three names, and nginx accepts connections at all.

Brotli module installation still waits for item I to exist.

Expect the first run to be informative: if the old workflow never parsed the site templates (nginx.org's `nginx.conf` includes `conf.d/*.conf` only, and nothing added a `sites-enabled` include), then this is the first time `bubbly_http.conf` and `bubbly_https.conf` have ever been given to a real nginx.

## C. Split SSL into socket-wide vs per-site — done 2026-08-05

**As built, which differs from the plan below in one important way.** The socket-wide values could *not* go into `conf.d/` at the `http` level: Debian and Ubuntu already set `ssl_protocols`, `ssl_prefer_server_ciphers` and `keepalive_timeout` in their own `nginx.conf`, and repeating any of them there is a fatal `directive is duplicate`. CI caught it on both platforms. So the profile lives in `directive/bubbly_ssl-profile.conf`, included from a `server` block by both `sites-available/bubbly_default.conf` (authoritative, since the default server is where nginx reads protocols and groups from) and `directive/bubbly_rock-hard-ssl.conf` (a safety net, so an operator who skips the default server does not silently inherit the distribution's TLS 1.0/1.1). `conf.d/bubbly_ssl.conf` keeps only what the distribution does not touch: the shared session cache, ticket settings, and the OCSP resolver.

`bubbly_default.conf` uses `ssl_reject_handshake on;` and needs no certificate. CI asserts that no-SNI and unknown-SNI handshakes are refused, that an unknown `Host` on port 80 gets closed with no response, that the ACME passthrough still serves a token for a real site, and all three per-vhost TLS behaviours from [[tls-per-vhost-findings]].

Original plan, for reference:

Why: nginx docs, [Virtual server selection](https://nginx.org/en/docs/http/server_names.html) — "the protocol list is set by the OpenSSL library before the server configuration could be applied according to the name requested through SNI, thus, protocols should be specified only for a default server." Per-site `ssl_protocols` is therefore an illusion: the default server for `0.0.0.0:443` wins, silently, with no config-test error. No template carries `default_server` today, so the winner is the alphabetically-first `sites-enabled/*` file's first 443 block — i.e. some site's `www`→apex redirect block — and onboarding a site that sorts earlier silently changes TLS for every site on the box.

- New `conf.d/bubbly_ssl.conf` at http context: `ssl_protocols`, `ssl_ciphers`, `ssl_prefer_server_ciphers`, `ssl_ecdh_curve`, `ssl_session_cache`, `ssl_session_tickets`, `ssl_session_timeout`, `ssl_session_ticket_key` (commented out — see item F), `resolver`, `resolver_timeout`, `keepalive_timeout`. Makes the session-cache-size `[WARNING]` structurally impossible to trip, gives one resolver cache instead of one per server block, and puts the Mozilla profile choice in exactly one place.
- `directive/bubbly_rock-hard-ssl.conf` keeps only genuinely per-server directives — `ssl_stapling`, `ssl_stapling_verify` — plus a `[WARNING]` header explaining the split and pointing at the conf.d file. Keep the filename: README and every already-deployed site file include it, and having both files present is backward compatible, since server-level values simply shadow http-level ones without error.
- New `sites-available/bubbly_default.conf`: catch-all `listen 80 default_server;` / `listen 443 ssl default_server;`, `server_name _;`, using `ssl_reject_handshake on;` as the single default — it needs nginx 1.19.4+, which the Ubuntu 26.04 floor comfortably clears, so the default server needs **no certificate** and no self-signed generation step. `[WARNING]`: exactly one default server per listen address:port, or nginx fails with `a duplicate default server`; enable once per server.
- `ssl_conf_command` is also available at this floor (1.19.4+), so TLS 1.3 ciphersuite selection is now possible via `ssl_conf_command Ciphersuites=…` — relevant only if the answer to the open question below is that per-site suites are genuinely wanted.
- README: new step for enabling the default server once per server, alongside step 4.

## D. Stop `expires` leaking to every vhost — done 2026-08-05

Built as planned: the `expires $expires;` line is gone from `conf.d/expires-map.conf`, which now only defines the variable, with a `[WARNING]` recording what changed and that the map is inert until a site includes `groups/performance-common.conf`. CI asserts both directions, using the ACME challenge response as the negative probe — it is `text/plain`, so it used to collect the map's `1y` fallback, and now comes back with no `Expires` at all, while `text/html` on the HTTPS site still returns `epoch`/`no-cache`.

Noticed while verifying, not acted on: a response from a site including both groups carries **two** `Cache-Control` headers — `no-cache` from `expires`, and `no-transform` from `directive/h5bp_no-transform.conf`. Valid HTTP, since clients merge them, but worth knowing before debugging cache behaviour. Also `default 1y` still catches `text/plain`, so `robots.txt` and friends on a Bubbly site get a year — worth revisiting when touching the map.

Original plan:

`conf.d/expires-map.conf:52` applies `expires $expires;` at **http** context, so it hits every vhost on the machine — including sites never onboarded to Bubbly — with `default 1y` for unlisted content types such as `text/plain`. Delete that line, keep the `map`. `location/h5bp_expires.conf` (via `groups/performance-common.conf`) already applies it per site, so the opt-in path is preserved. Behaviour change for anyone relying on the global default — call it out in the README/release notes.

## E. Per-site rate limits alongside the global ones — done 2026-08-05

Built as planned: site-scoped zones keyed `$server_name$binary_remote_addr` (`siteReqPerSec1/10/20`, `siteConPerIP`) alongside the originals, plus `directive/bubbly_limits_site_20.conf`. Keyed on `$server_name` not `$host`, because `$host` comes from the request and a catch-all server would let one client mint unlimited keys and exhaust the zone. CI proves the difference: hammer alpha.test at 1r/s with no burst, then ask beta.test once — `503` with the server-wide zone, `200` with the site-scoped one, identically on both platforms.

**`limit_req` and `limit_conn` never apply to a `return` response.** Discovered when the first version of the test hammered `/` and got five 308s with no 503 on either platform. `return` is handled in the rewrite phase, which precedes the preaccess phase where the limits are evaluated, so the response is finalised without consulting them — meaning Bubbly's HTTP-to-HTTPS redirect **cannot** be rate-limited by these directives at all. Both limits files carry a `[WARNING]` about it, and the CI test uses the ACME path, which serves a static file and so reaches preaccess.

**Trimmed to one zone per kind, on the user's call, and sized by state lifetime.** Nine zones reserving 36MB became five reserving 15MB: `reqPerSec20:2m`, `conPerIP:5m`, `siteReqPerSec20:2m`, `siteConPerIP:5m`, `conPerServer:1m`. Four request zones differing only in rate were referenced by nothing; the file now says to copy a line and rename it if a second rate is wanted.

The sizing reasoning, documented in the file: a `limit_req` state is ~128 bytes and survives only about `burst/rate` seconds past a client's last request — five seconds at 20r/s with burst 100 — so the zone needs just the clients active in that window. A `limit_conn` state is ~64 bytes but lives as long as the connection, and Bubbly sets `keepalive_timeout 300s`, so those zones need to be several times larger. `conPerServer` holds one state per site, not per client, so 1m is already thousands of times more than needed.

Two further interactions worth remembering: clients behind NAT count as one, so raise the *rate* not the size for them; and `limit_conn conPerServer 2000` is unreachable unless `worker_processes × worker_connections` exceeds it, which at Debian and Ubuntu's 768 per worker needs three cores.

CI rewrites only `rate=20r/s` to `1r/s` before the isolation test, leaving the key expressions — the thing under test — exactly as shipped.

**Renamed for what they key on, not their rate** (user's call): `reqPerSec20`→`reqPerIP`, `siteReqPerSec20`→`siteReqPerIP`, and `bubbly_limits_{20,site_20,server_2k}.conf`→`bubbly_limits_{ip,site,server}.conf`. The rate had been encoded in the zone name, the rate itself and the filename, so changing it meant renaming or lying. `rate=` must live on `limit_req_zone` — `limit_req` accepts only `burst=` and `nodelay`/`delay=` — so a second rate means a second zone.

### Making the limits survivable behind shared addresses (2026-08-05)

The NAT question turned out to have a worse sibling. All four mitigations shipped:

1. **Scope to PHP.** The recommended placement is now inside `location ~ \.php$`, with a commented include in `location/bubbly_extensionless-php.conf`. At server level every asset is counted, so one cold-cache page load — around seventy requests for a median page — spends most of a 100 burst by itself. Limiting only PHP makes a page load cost roughly one token, which turns NAT from a real risk into a non-issue.
2. **`directive/bubbly_real-ip.conf`.** Behind a proxy or CDN, `$binary_remote_addr` is the proxy, so every zone collapses to one bucket for the entire audience — silently. Bubbly had no `real_ip` or `proxy_protocol` handling at all. Ships fully commented, with the critical warning that `set_real_ip_from` on a range you do not control lets anyone in it forge their address and evade the limit. Cloudflare's ranges are deliberately not copied in, only the commands to fetch them, since they go stale.
3. **429, not 503.** `limit_req_status`/`limit_conn_status` are 429, and rejections log at `warn` rather than nginx's `error` — being limited is expected under load, and a 503 on a stylesheet reads as an outage.
4. **`delay=50` replaces `nodelay`.** Half the burst passes immediately, the rest is paced instead of refused, so a shared address degrades into slowness. `nodelay` remains an `[OPTION]`.

CI asserts the realip module exists on both platforms, that the real-ip include parses with an option enabled, and that a rejection really is 429.

Still open, and now a much smaller step: whether to include `bubbly_limits_site.conf` by default. Nothing limiting ships enabled today — the never-included list is `bubbly_limits_{ip,site,server}.conf`, `bubbly_uploads.conf` (so uploads sit at nginx's 1m, not Bubbly's 10M), `bubbly_logs.conf`, `location/bubbly_errors.conf` and `location/bubbly_methods.conf`.

Original plan:

`conf.d/bubbly_limits.conf` keys its zones on `$binary_remote_addr` alone, so one client's traffic to site A spends site B's budget and `limit_conn conPerIP 20` is a box-wide per-IP cap. Add site-scoped zones keyed `$server_name$binary_remote_addr` (`siteReqPerSec20`, `siteConPerIP`) and a `directive/bubbly_limits_site_20.conf` variant; keep the existing global zones and files for back-compat and document the trade-off with `[OPTION]`/`[WARNING]`. Zones consume shared memory whether used or not, so keep the new ones at the current 1m/10m sizes. Low risk: neither limits file is included by either group today, so this is entirely opt-in.

## F. Ticket key — commented out by default, opt-in as a separate setup step

Decided 2026-08-05 by the user: keep the key mechanism, but make generating it and enabling it a **separate, conditional setup step** — "run this command, uncomment this line, if your nginx is old enough to need it" — rather than part of the mandatory happy path.

Rationale, from the nginx docs for `ssl_session_ticket_key`: "The directive is necessary if the same key has to be shared between multiple servers. By default, a randomly generated key is used." nginx builds each `SSL_CTX` in the master process before forking, so workers inherit that random key — omitting the directive does **not** break resumption across workers, even pre-1.23.2. Below 1.23.2 what you lose is key persistence across reloads (every `service nginx reload`, including certbot's renewal deploy-hook, mints a new one) and periodic rotation. Both degrade gracefully: a client presenting a stale ticket just performs a full handshake.

- **The version gate is nginx 1.23.2**, when the shared session cache began auto-generating, storing and periodically rotating ticket keys. The Ubuntu 26.04 floor clears it everywhere, so no *supported* platform needs the explicit key for version reasons — that reason survives only as a footnote for anyone deliberately running older nginx.
- Ship `ssl_session_ticket_key` **commented out** in `conf.d/bubbly_ssl.conf` (see item C). The primary reason to enable it is now the version-independent one: several nginx instances behind a load balancer that must resume each other's tickets, which is the directive's documented purpose ("necessary if the same key has to be shared between multiple servers").
- `[WARNING]` on the modern path: auto-generated keys come from `ssl_session_cache shared:…`. Setting the cache to `off` or `none` silently loses rotation as well.
- This also removes a first-run footgun. Today `directive/bubbly_rock-hard-ssl.conf:42` references `/etc/nginx/ssl/ticket.key` unconditionally, so an operator who skips README step 2 gets an `[emerg]` on a missing file. Commented out by default, a fresh clone → copy-configs → enable-site sequence cannot fail this way.
- Land this with or after item C. Before C the line lives in the per-site `bubbly_rock-hard-ssl.conf`, so "uncomment this line" would be once per site; after C it is one edit per server.
- `bubbly_generate-tickets.sh` is a single `openssl rand -out … 80` — instant. Add `chmod 600` (it currently lands at the caller's umask, i.e. a world-readable secret), print the version guidance on completion, and document the two-key rotation recipe (`ssl_session_ticket_key current.key;` then `previous.key;` — first encrypts, the rest decrypt).
- README: demote step 2 from the mandatory path to a clearly-labelled conditional step, and drop its stale "this might take a while / have a seat / 15 minutes" wording — that has not matched what the script does for some time.
- Multi-site nuance to document, not solve: on 1.23.2+ the auto key is stored in the shared cache zone, so vhosts sharing `shared:SSL:10m` still share ticket keys. This makes the key rotating rather than static, but resumption is still not scoped per site, so per-site TLS settings remain not a security boundary. Per-site isolation would need per-site cache zones — offer as an `[OPTION]`, not a default.
- CI: no job should generate the key file by default, proving the shipped config loads without it. One job may uncomment the line and generate a key to cover the shared-key path.

## G. PHP — per-version upstreams and per-site selection — done 2026-08-05

Built as planned, with one deliberate deviation: **`fastcgi_pass php_sockets;` stays the shipped default and the variable form is `[OPTION] 2`**, rather than switching to `$bubbly_php` outright. Two reasons. nginx resolves a *literal* upstream name when the config loads, so a typo fails `nginx -t`; a variable is resolved per request, so a missing or misspelled `set` is a 502 with a clean config test. And an operator upgrading from an older Bubbly gets our replaced location file but keeps their own site files, which would have no `set` — the variable form would have broken every site on upgrade.

There is now an upstream per supported branch (`php85`, `php84`, `php83`, `php82`), all active, plus `php_sockets` as the shared default pointing at the newest. `sites-available/bubbly_https.conf` carries a commented `set $bubbly_php php85;`.

**The support dates in the old file were all wrong** — they looked like active-support ends from a superseded schedule. PHP retires branches at the end of a calendar year, so 8.3 runs to 2027-12-31, not the 2026-11-23 the file claimed. Corrected against php.net with active and security windows stated separately; all four branches are still supported as of 2026-08.

Also documented, both confirmed against the nginx docs: `fastcgi_pass` with a variable searches server groups first and falls back to a resolver, and `fastcgi_keep_conn on` is "necessary, in particular, for keepalive connections to function" — so it does nothing without `keepalive` in the upstream. Enabling keepalive pins an FPM child per idle connection, so `worker_processes × keepalive` must fit inside `pm.max_children`.

CI proves per-site selection with no third-party repo: each distribution ships one branch, so alpha.test is aimed at the installed one and beta.test at an absent one. 200 from one and 502 from the other means they resolved different upstreams. Usefully, the two platforms exercise different branches — php85 on Ubuntu 26.04, php84 on Debian 13.

Original plan:

`conf.d/php_sockets.conf:2` defines a single `upstream php_sockets` and `location/bubbly_extensionless-php.conf:18` hard-codes `fastcgi_pass php_sockets;`. `upstream` is http-context only, so a site block cannot define its own — every site shares one FPM socket. The `[OPTION]` list also invites the wrong fix: uncommenting two `server unix:…` lines makes nginx round-robin between PHP versions rather than route per site.

- `conf.d/php_sockets.conf`: one upstream per still-supported version, **all uncommented** — `php85`, `php84`, `php83`, `php82` — keeping descending order, the "Supported until" comments, and the newest as the default target per [[feedback_version_lists]]. Add `keepalive 8;` (or an `[OPTION]` for it) inside each: without it, the `fastcgi_keep_conn on;` at `location/bubbly_extensionless-php.conf:14` has no connection cache to use and is a no-op.
- Add a `[WARNING]` that several `server` lines in one upstream is round-robin load balancing across PHP versions, not per-site routing.
- Retain an `upstream php_sockets` alias pointing at the newest version so already-deployed site files keep working.
- `location/bubbly_extensionless-php.conf`: `fastcgi_pass $bubbly_php;`. Variables in `fastcgi_pass` are matched against declared upstream group names and predate 1.18. The site template carries `set $bubbly_php php85;` as an `[OPTION]` beside the other core options.
- `[WARNING]`: a missing or misspelled `set` is a runtime 502, not an `nginx -t` failure — the variable form gives up config-time validation. Do **not** try to supply an http-level default via `map`; `map` plus `set` on the same variable name fails with `the duplicate "…" variable`.
- Rejected alternative: one location file per version, which duplicates the 15-line fastcgi body N times.
- Out of scope, worth a README note: separate FPM **pools** per site (own user, own `pm.max_children`). One shared pool lets a single busy site starve the others no matter what nginx does.

## H. `bubbly_renew-ssl.sh` rate limits (independent, land anytime)

`bubbly_renew-ssl.sh:13` passes `--force-renew` unconditionally. Per-site invocations on a multi-domain box burn Let's Encrypt allowances — 5 duplicate certificates per week for an identical name set, 50 certs per week per registered domain. Make it opt-in via a wrapper flag, or drop it and let certbot's own "not yet due" logic run, and document `--cert-name` for managing several lineages on one server.

## I. Brotli (added 2026-08-05)

The packaging decision in [[nginx-version-floor]] makes Brotli available to Bubbly for the first time: Ubuntu 26.04 ships it for its own nginx, and the operator is now told to use the distribution's build.

- New `directive/bubbly_brotli.conf` mirroring `bubbly_gzip.conf`'s structure: `brotli on;`, `brotli_comp_level` as an `[OPTION]`, `brotli_min_length`, and a `brotli_types` list kept in step with `gzip_types`.
- `[WARNING]`: needs `libnginx-mod-http-brotli-filter` installed (plus `-static` to serve pre-compressed `.br` files). Without the package, `brotli on;` is an unknown directive and the **whole config fails to load** — so keep it opt-in per site rather than adding it to `groups/performance-common.conf`, where a missing module would take every site down at once.
- Keep gzip alongside it, not replaced: Brotli and gzip coexist, with clients choosing via `Accept-Encoding`.
- README: the module packages are already named in Requirements; add the directive to whatever section covers performance includes.

## Version marker

Every site template says `Config from Bubbly v3.0-beta1`. Bump to `v3.0-beta2` in the same pass as C, since the SSL split and the new default-server file change the documented deploy steps.

## Open questions

- **Answered by measurement**, see [[tls-per-vhost-findings]]: `ssl_ciphers` does apply per vhost, while `ssl_protocols` and `ssl_ecdh_curve` come from the default server. The remaining question is a scope decision, not a technical one: should Bubbly support genuinely different TLS profiles per site — which now provably requires separate listen sockets, a distinct IP or port — or standardise on one socket-wide profile with per-site ciphers as the only variation? Recommendation: standardise, and document the separate-socket escape hatch as a `[WARNING]`.

Answered 2026-08-05: Ubuntu 26.04 and Debian 13 package versions (recorded in [[nginx-version-floor]]); and whether OpenSSL 3.0 rejects a whole `ssl_ecdh_curve` list — moot, since no supported platform ships OpenSSL below 3.5.
