---
name: nginx-version-floor
description: Bubbly v3 targets Ubuntu 26.04 / Debian 13 — nginx 1.25.1+ and OpenSSL 3.5+ — dropping Ubuntu 22.04 and 24.04, with the verified package versions behind that decision.
metadata:
  type: project
---

Decided 2026-08-05, revised the same day from an initial nginx 1.18 / Ubuntu 22.04 floor: Bubbly **v3.0** raises its floor to **Ubuntu 26.04 LTS**, on the grounds that v3 is already a major breaking change and should not be held back by 22.04. In feature terms the requirement is **nginx 1.25.1 or newer and OpenSSL 3.5 or newer**.

Package versions verified against packages.ubuntu.com and packages.debian.org on 2026-08-05:

| Platform | nginx | OpenSSL | Qualifies |
|---|---|---|---|
| Ubuntu 26.04 LTS (resolute) | 1.28.3 | 3.5.5 | Yes — the reference target |
| Debian 13 (trixie) | 1.26.3 | 3.5.6 | Yes — the **lowest supported nginx**, so this is the version CI should treat as the floor |
| Ubuntu 25.10 (questing) | 1.28.0 | 3.5.3 | Meets both gates, but end of life 2026-07-01 |
| Ubuntu 25.04 (plucky) | 1.26.3 | 3.4.1 | No — OpenSSL below 3.5; end of life 2026-01-17 |
| Ubuntu 24.10 (oracular) | 1.26 | 3.3 | No — OpenSSL below 3.5; end of life 2025-07-10 |
| Ubuntu 24.04 LTS (noble) | 1.24.0 | 3.0.13 | No — fails both gates |
| Ubuntu 22.04 LTS (jammy) | 1.18.0 | 3.0.2 | No — fails both gates |
| Debian 12 (bookworm) | 1.22.1 | 3.0.20 | No — fails both gates |

OpenSSL is the binding gate, not nginx: every Ubuntu from 24.10 onward already clears nginx 1.25.1, and OpenSSL 3.5 first reached Ubuntu in 25.10. Since all three interim releases between the LTSs are now end of life, 26.04 is the earliest Ubuntu that is both new enough and supported.

The two gates that set the floor, both already in the shipped config:

- **`http2 on;`** needs nginx 1.25.1+ — used at `sites-available/bubbly_https.conf:20` and `:50`. On older nginx this is `unknown directive "http2"` and the entire site file fails to load. The pre-1.25.1 spelling is the `listen 443 ssl http2;` parameter, which is deprecated but still supported in current nginx.
- **`X25519MLKEM768`** in `ssl_ecdh_curve` needs OpenSSL 3.5+ — used at `directive/bubbly_rock-hard-ssl.conf:28`. Older OpenSSL rejects the group list as a whole rather than skipping a name it does not recognise, so `nginx -t` fails.

Everything else the refactor wants sits comfortably inside this floor: `ssl_reject_handshake` and `ssl_conf_command` (both nginx 1.19.4+), and ticket-key auto-generation and rotation from the shared session cache (1.23.2+). See [[multisite-refactor-plan]].

## Packaging: distribution only

Also decided 2026-08-05: install nginx from the distribution's own archive on the latest LTS, and recommend **no third-party repositories**. Ubuntu 26.04's 1.28.3 already clears both gates, so nginx.org's packages gain nothing — and lose one thing: they ship **no Brotli**. Their dynamic modules are geoip, image-filter, njs, perl, xslt, otel and acme (that last since 1.29.1). Ubuntu provides Brotli as `libnginx-mod-http-brotli-filter` and `libnginx-mod-http-brotli-static` (1.0.0~rc-7build3, source `libnginx-mod-http-brotli`, section `universe`), which depend on `nginx-abi-1.28.3-1` and so only fit the distribution's own build.

Consequences:

- `.github/workflows/nginx.yml` should install Ubuntu's nginx instead of nginx.org mainline (item B of the plan). This also settles the sites-enabled question: Debian and Ubuntu's `nginx.conf` includes `modules-enabled/*.conf`, `conf.d/*.conf` **and** `sites-enabled/*`, whereas nginx.org's includes only `conf.d/*.conf`. Bubbly's whole `sites-available`/`sites-enabled` layout assumes Debian packaging, so the distro build is the honest thing to test against.
- Brotli becomes available to Bubbly for the first time — item I of the plan.
- Worth watching, not acting on: nginx.org's `nginx-module-acme` (1.29.1+) could eventually replace certbot as Bubbly's issuance path, but it is mainline-only and above the 1.28 floor.
