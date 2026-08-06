# Bubbly

_For configuring Certbot with Nginx as quickly and securely as possible._

[![Nginx Config](https://github.com/eustasy/Bubbly/actions/workflows/nginx.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/nginx.yml)
[![Normal (Shell)](https://github.com/eustasy/Bubbly/actions/workflows/sh.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/sh.yml)
[![Deploy _site to GitHub Pages](https://github.com/eustasy/Bubbly/actions/workflows/pages.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/pages.yml)
[![Maintainability](https://qlty.sh/gh/eustasy/projects/Bubbly/maintainability.svg)](https://qlty.sh/gh/eustasy/projects/Bubbly)

If you want an instant A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html?d=lewisgoddard.me.uk) and A score on [SecurityHeaders.io](https://securityheaders.io/?q=lewisgoddard.me.uk&followRedirects=on), then this is what you'll need to do. You won't need any familiarity with [Certbot](https://github.com/certbot/certbot), [Let's Encrypt](https://letsencrypt.org/), the ACME spec, or SSL in general, just basic Nginx configuration.

## Requirements

* **Nginx 1.25.1+** for the `http2` directive,
* **OpenSSL 3.5+** for the `X25519MLKEM768` post-quantum group.

> _Check with `nginx -V`, which reports the OpenSSL Nginx was built against, not the `openssl` on your `$PATH`. Consider deploying on an unsupported releases using [Bubbly 2.2.0](https://github.com/eustasy/Bubbly/tree/2.2.0)._

| Platform | Nginx | OpenSSL | Supported |
| --- | --- | --- | --- |
| Ubuntu 26.04 LTS | 1.28 | 3.5 | Yes |
| Debian 13 | 1.26 | 3.5 | Yes |
| Ubuntu 25.10 | 1.28 | 3.5 | Meets both, but end of life |
| Ubuntu 24.04 LTS | 1.24 | 3.0 | No |
| Debian 12 | 1.22 | 3.0 | No |

We recommend the use of the distribution's own Nginx, with no third-party repositories.

## Installation

### 1. Install Certbot and Clone Bubbly

We'll start off by cloning the project into the home folder with git.

```bash
cd &&
sudo apt install git certbot &&
git clone https://github.com/eustasy/Bubbly
```

### 2. Copy config blocks

Copy the configuration into place. Run it again whenever you pull a newer Bubbly.

```bash
~/Bubbly/bubbly_copy-configs.sh
```

This installs `conf.d/bubbly_ssl.conf`, which Nginx loads by itself: the shared TLS session cache and the OCSP resolver. Protocols, key exchange groups and ciphers live in `directive/bubbly_ssl-profile.conf` instead, because Nginx takes those from the default server for the socket whatever a site file asks for — hence the next step.

### 3. Enable the default server

Once per server, before any site. It answers whatever no site claims: an unknown `Host`, a connection with no SNI, a probe at your IP address.

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/bubbly_default.conf /etc/nginx/sites-enabled/bubbly_default.conf
sudo nginx -t && sudo service nginx reload
```

The `rm` drops the distribution's default site, which also claims `default_server`; with two, Nginx refuses to start.

This matters more than it looks. The default server sets the TLS protocol list and key exchange groups for **every** site on the machine, so without one of your own the role falls to whichever `sites-enabled/` file sorts first — and a new site sorting earlier would change them underneath you. Site files include the same profile as a safety net.

### 4. Configure & Enable Verification

Copy the verification template and replace `example.com` with your domain.

```bash
sudo cp /etc/nginx/sites-available/bubbly_http.conf /etc/nginx/sites-available/example.com_http.conf
sudo nano /etc/nginx/sites-available/example.com_http.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo ln -s /etc/nginx/sites-available/example.com_http.conf /etc/nginx/sites-enabled/example.com_http.conf
sudo nginx -t && sudo service nginx reload
```

Or, to keep an existing site running while you migrate, add `include location/bubbly_well-known-passthrough.conf;` to it instead.

### 5. Fetch Certificates

```bash
~/Bubbly/bubbly_renew-ssl.sh -d example.com -d www.example.com
```

It will ask for the root password and an email address, and takes a few seconds.

Certbot installs a systemd timer that runs `certbot renew` twice a day, and the `--deploy-hook` recorded in `/etc/letsencrypt/renewal/example.com.conf` reloads Nginx after each success. No cron job needed.

Renewal being automatic is why this script always passes `--force-renew`: running it by hand means you want a certificate now. Don't loop it — [Let's Encrypt allows 5 certificates per identical set of names every 7 days](https://letsencrypt.org/docs/rate-limits/), refilling one every 34 hours, and that limit cannot be raised. Add `--dry-run` to rehearse against staging.

### 6. Start using the Certificates

Copy the live template alongside the verification one. Review its `[OPTION]`s more carefully — the certificate paths have to match the domain you requested — and the `[OPTION]`s and `[WARNING]`s in the files it includes.

```bash
sudo cp /etc/nginx/sites-available/bubbly_https.conf /etc/nginx/sites-available/example.com_https.conf
sudo nano /etc/nginx/sites-available/example.com_https.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo ln -s /etc/nginx/sites-available/example.com_https.conf /etc/nginx/sites-enabled/example.com_https.conf
sudo nginx -t && sudo service nginx reload
```

Keep `example.com_http.conf` symlinked permanently. It serves all HTTP traffic, ACME challenges included, so renewals keep working even after a certificate has expired.

### Optional: shared session ticket keys

Nginx 1.23.2+ generates and rotates ticket keys itself, in the shared session cache. You only need your own if **several Nginx instances behind a load balancer** have to resume each other's tickets.

```bash
~/Bubbly/bubbly_generate-tickets.sh
```

Then uncomment `ssl_session_ticket_key` in `/etc/nginx/conf.d/bubbly_ssl.conf` and reload. Run it again to rotate: the current key moves to `ticket.old.key` and a fresh one is written, so issued tickets keep working. Nginx encrypts with the first key listed and decrypts with any of them, so keep the newest on top. Both are written `600`, since the key decrypts captured sessions.

Either way, every site shares one session cache — and on 1.23.2+ the automatic keys live in it — so a session begun on one site can be resumed against another. Fine across sites you own, but one site's TLS settings are therefore not a boundary around it; a site needing one declares its own `ssl_session_cache` zone.

## Configuration

Every knob is marked `[OPTION]` in the configuration files, with `[DEFAULT]` on the active choice and `[WARNING]` where one can bite. Add an `include` inside the `server` block of your site file, or inside `location ~ \.php$` where noted.

| Want | Advice | Change |
| --- | --- | --- |
| Brotli | Recommended | install `libnginx-mod-http-brotli-filter`, then uncomment in `groups/performance-common.conf` |
| Per-site log files | Recommended with more than one site | include `directive/bubbly_logs.conf` |
| A Content Security Policy | Recommended, carefully | Option 2 or 3 in `directive/bubbly_security-headers.conf` |
| Only expected request methods | Optional hardening | include `location/bubbly_methods.conf` |
| Uploads over 1 MB | Optional | include `directive/bubbly_uploads.conf` — 10M |
| Custom 404 and 50x pages | Optional | include `location/bubbly_errors.conf`, and provide the files |
| PHP that runs longer than 60s | Only if needed | raise `fastcgi_read_timeout` in `location/bubbly_extensionless-php.conf` |
| A per-site connection cap | Only if needed | include `directive/bubbly_limits_server.conf` |
| TLS 1.3 only | Only if essential | Option 1 in `directive/bubbly_ssl-profile.conf` — drops pre-2020 clients |
| HSTS across subdomains | Only if essential | Option 2 in `directive/bubbly_security-headers.conf` |

Nginx caps request bodies at 1 MB, so uploads fail with 413 before reaching PHP until `bubbly_uploads.conf` is included — and PHP's own `upload_max_filesize` and `post_max_size` have to allow them too. Without `bubbly_logs.conf`, the HTTPS block logs to the distribution's shared log and HTTP traffic is not logged at all. HSTS and TLS 1.3-only are marked essential-only because both are hard to walk back: the first commits subdomains that may not exist yet to HTTPS for two years, and the second refuses anything older than roughly 2020.

### Behind a proxy or CDN

_Essential when Nginx sits behind one; pointless otherwise._

`$binary_remote_addr` is the proxy, so rate limits count your whole audience as one client and every log line records the proxy. `directive/bubbly_real-ip.conf` recovers the real address.

> _Only trust ranges you control. Naming one you do not own lets anyone in it forge their address._

### Rate limiting

_Optional, and deliberately not enabled by default:_ a safe rate depends on whether you are behind a proxy and whether clients speak HTTP/2, neither of which Bubbly can know.

Uncomment an include inside `location ~ \.php$` — see `location/bubbly_extensionless-php.conf` — so only the requests that cost something are counted, rather than every stylesheet and image alongside them. Zones, rates and sizes live in `conf.d/bubbly_limits.conf`.

### PHP Versions

_Optional; nothing to do unless you want a version other than the one your release ships._

Ubuntu 26.04 LTS ships PHP 8.5, which `conf.d/php_sockets.conf` selects by default. Run `ls /etc/php/` to list the versions installed and `ls /var/run/php/` the sockets that exist.

Multiple PHP versions can be easily installed: `php8.5-fpm` and `php8.4-fpm` each get their own `/etc/php/` tree, systemd unit and socket. Each release only _carries_ one, though — 26.04 has 8.5, 24.04 has 8.3, Debian 13 has 8.4 — so extra versions come from Ondřej Surý:

* Ubuntu 22.04 and 24.04: [`ppa:ondrej/php`](https://launchpad.net/~ondrej/+archive/ubuntu/php)
* Ubuntu 26.04 and Debian: [packages.sury.org/php](https://packages.sury.org/php/), which the PPA is merging into

Their version strings sort above the distribution's, so `apt` prefers their builds for every PHP package once enabled. To put a site on a given version, uncomment Option 2 in `location/bubbly_extensionless-php.conf` and set `$bubbly_php` in each site file. Give each site its own FPM pool while you are there, so one cannot exhaust the workers or read another's sessions.

---

![Screenshot of SSLLabs.com](https://raw.githubusercontent.com/eustasy/Bubbly/main/screenshot_ssllabs.com.png)

![Screenshot of SecurityHeaders.io](https://raw.githubusercontent.com/eustasy/Bubbly/main/screenshot_securityheaders.io.png)
