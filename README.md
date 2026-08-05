# Bubbly

_For configuring Certbot with Nginx as quickly and securely as possible._

[![Nginx Config](https://github.com/eustasy/Bubbly/actions/workflows/nginx.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/nginx.yml)
[![Normal (Shell)](https://github.com/eustasy/Bubbly/actions/workflows/sh.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/sh.yml)
[![Deploy _site to GitHub Pages](https://github.com/eustasy/Bubbly/actions/workflows/pages.yml/badge.svg)](https://github.com/eustasy/Bubbly/actions/workflows/pages.yml)
[![Maintainability](https://qlty.sh/gh/eustasy/projects/Bubbly/maintainability.svg)](https://qlty.sh/gh/eustasy/projects/Bubbly)

If you want an instant A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html?d=lewisgoddard.me.uk) and A score on [SecurityHeaders.io](https://securityheaders.io/?q=lewisgoddard.me.uk&followRedirects=on), then this is what you'll need to do. You won't need any familiarity with [Certbot](https://github.com/certbot/certbot), [Let's Encrypt](https://letsencrypt.org/), the ACME spec, or SSL in general, just basic Nginx configuration.

## Requirements

Bubbly 3.x targets **Ubuntu 26.04 LTS**. What the configuration actually needs is **Nginx 1.25.1 or newer**, for the `http2` directive, and **OpenSSL 3.5 or newer**, for the `X25519MLKEM768` post-quantum key exchange group. `nginx -V` reports both the Nginx version and the OpenSSL it was built against, which is the pairing that matters — the `openssl` command on your `$PATH` can be an entirely different build.

| Platform | Nginx | OpenSSL | Supported |
| --- | --- | --- | --- |
| Ubuntu 26.04 LTS | 1.28 | 3.5 | Yes |
| Ubuntu 25.10 | 1.28 | 3.5 | Works, but end of life |
| Ubuntu 25.04 | 1.26 | 3.4 | No |
| Ubuntu 24.10 | 1.26 | 3.3 | No |
| Ubuntu 24.04 LTS | 1.24 | 3.0 | No |
| Ubuntu 22.04 LTS | 1.18 | 3.0 | No |
| Debian 13 | 1.26 | 3.5 | Yes |
| Debian 12 | 1.22 | 3.0 | No |

OpenSSL is what binds here, not Nginx — everything from Ubuntu 24.10 onward already clears 1.25.1. OpenSSL 3.5 first reached Ubuntu in 25.10, so that is the earliest release the post-quantum group works on at all, but every interim release between the two LTSs has since gone end of life: 24.10 in July 2025, 25.04 in January 2026, and 25.10 on 1 July 2026. That leaves 26.04 as the earliest Ubuntu that is both new enough and still supported.

So the recommendation is the plainest one available: the latest LTS, with the Nginx it ships and no third-party repositories. Ubuntu 26.04's 1.28 clears both requirements on its own, and it is the only route that offers Brotli — Ubuntu packages that as `libnginx-mod-http-brotli-filter` and `libnginx-mod-http-brotli-static`, loaded automatically as dynamic modules, while [nginx.org's own packages](https://nginx.org/en/linux_packages.html#Ubuntu) ship geoip, image-filter, njs, perl, xslt, otel and acme modules but [no Brotli at all](https://codeberg.org/oerdnj/deb.sury.org/issues/67#issuecomment-14373032). Those Brotli packages depend on `nginx-abi-1.28.3-1`, so they only fit the distribution's own build; they do live in `universe` rather than `main`.

On the unsupported releases, use [Bubbly 2.2.0](https://github.com/eustasy/Bubbly/tree/2.2.0) instead. It uses the older `listen 443 ssl http2;` spelling and a classical `ssl_ecdh_curve`, so it runs on all of them.

Raising OpenSSL on those releases is not practical either. Nginx mainline from nginx.org raises Nginx but not OpenSSL, because those packages link against the system OpenSSL — and `ppa:ondrej/nginx`, long the other way to get newer Nginx on Ubuntu, was [deprecated in January 2026](https://codeberg.org/oerdnj/deb.sury.org/issues/67) at 1.28.x, with its packages removed that April.

Both requirements are marked `[WARNING]` in the configuration files, next to the change needed to do without them.

### PHP

Ubuntu 26.04 ships PHP 8.5, which is what `nginx-config/conf.d/php_sockets.conf` selects by default, so a single-version setup needs nothing extra.

To see what you have, `php -v` gives the version of the PHP CLI on your `$PATH`, `ls /etc/php/` lists every version installed, and `ls /var/run/php/` shows the FPM sockets that actually exist — that last one being what `php_sockets.conf` has to match.

Running **several versions side by side** — the reason `php_sockets.conf` offers a choice — needs no special packaging. Debian and Ubuntu version PHP throughout, so `php8.5-fpm` and `php8.4-fpm` install happily alongside each other, each with its own `/etc/php/8.5/` and `/etc/php/8.4/` tree, its own systemd unit, and its own socket under `/var/run/php/` — the paths already listed in `php_sockets.conf`.

What you need a third party for is somewhere to _get_ the extra versions, because each release only carries one: Ubuntu 26.04 has php8.5 and nothing else, Ubuntu 24.04 has php8.3, Debian 13 has php8.4. For any other version, use Ondřej Surý's packages:

* Ubuntu 22.04 and 24.04: [`ppa:ondrej/php`](https://launchpad.net/~ondrej/+archive/ubuntu/php)
* Ubuntu 26.04 and Debian: [packages.sury.org/php](https://packages.sury.org/php/), which the PPA is being merged into

Note that their version strings sort above the distribution's own, so once the repository is enabled `apt` will generally prefer its builds for every PHP package — including the version your release already shipped.

To put a site on a particular version, uncomment Option 2 in `location/bubbly_extensionless-php.conf` and set `$bubbly_php` in each site file to one of the upstream names in `conf.d/php_sockets.conf`. Both files explain the trade-off: selecting per site means the upstream name is resolved per request, so a typo becomes a 502 rather than something `nginx -t` catches.

Worth doing at the same time, though it is PHP-FPM configuration rather than Nginx: give each site its own **pool** instead of sharing `www`. A pool has its own user, its own `pm.max_children` and its own opcache, so one site cannot read another's session files or consume all the workers. Sharing a single pool means one busy or wedged site stalls every other site on the machine, whatever Nginx is told to do.

## 1. Install Certbot and Clone Bubbly

We'll start off by cloning the project into the home folder with git.

```bash
cd &&
sudo apt install git certbot &&
git clone https://github.com/eustasy/Bubbly
```

## 2. Copy config blocks

Copy the Nginx configuration over to the Nginx area. Run this again whenever you pull a newer Bubbly.

```bash
~/Bubbly/bubbly_copy-configs.sh
```

Among other things this installs `conf.d/bubbly_ssl.conf`, which Nginx loads by itself, holding the TLS session cache and the OCSP resolver that every site shares.

The protocol list, key exchange groups and cipher list live in `directive/bubbly_ssl-profile.conf` instead, because Nginx cannot vary them per site: a handshake begins before SNI has chosen a site, so those values always come from the default server for the listening address, whatever a site file asks for. Which is why the next step matters more than it looks.

## 3. Enable the default server

Once per server, before enabling any site. This gives Nginx something deliberate to answer with when a request matches no site at all: an unknown `Host` header, a connection with no SNI, or a probe aimed straight at your IP address.

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/bubbly_default.conf /etc/nginx/sites-enabled/bubbly_default.conf
sudo nginx -t && sudo service nginx reload
```

The `rm` removes the distribution's own default site, which also claims `default_server`; leaving both in place makes Nginx refuse to start with "a duplicate default server".

Without a default server of your own, the role falls to whichever file in `sites-enabled/` sorts first, and that file's first `server` block silently decides the TLS protocol list and key exchange groups for **every** site on the machine. Adding a site whose filename sorts earlier would change them underneath you.

`bubbly_default.conf` includes the TLS profile itself for exactly this reason, so the socket's protocols and groups are set deliberately rather than inherited from the distribution's `nginx.conf` — which on Debian and Ubuntu still permits TLS 1.0 and 1.1. Site files include the same profile as a safety net, so nothing is weakened if you skip this step, but the default server is what actually decides.

## 4. Configure & Enable Verification

Copy the verification site template and replace the instances of `example.com` in the file with your actual domain name.

```bash
sudo cp /etc/nginx/sites-available/bubbly_http.conf /etc/nginx/sites-available/example.com_http.conf
sudo nano /etc/nginx/sites-available/example.com_http.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo ln -s /etc/nginx/sites-available/example.com_http.conf /etc/nginx/sites-enabled/example.com_http.conf
sudo nginx -t && sudo service nginx reload
```

Alternatively, you can simply add `include location/bubbly_well-known-passthrough.conf;` to an existing site you want to continue working while we upgrade.

## 5. Fetch Certificates

Fetch your certificates like this:

```bash
~/Bubbly/bubbly_renew-ssl.sh -d example.com -d www.example.com
```

It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds.

Certbot will set up a systemd timer that runs `certbot renew` automatically twice a day. The `--deploy-hook` passed by the script is stored in `/etc/letsencrypt/renewal/example.com.conf`, so Nginx will be reloaded automatically after each successful renewal — no cron job or manual renewal needed.

Which is why this script always passes `--force-renew`: routine renewal is the timer's job, so running it by hand means you want a certificate now — a first issuance, a name added, a different key type, or recovery from a broken one. [Let's Encrypt allows 5 certificates per exact same set of names every 7 days](https://letsencrypt.org/docs/rate-limits/), refilling one every 34 hours, and that limit cannot be raised on request, so don't put this in a loop. Add `--dry-run` to rehearse against staging, which isn't rate limited.

## 6. Start using the Certificates

Copy the live site template alongside the verify config you already have. You'll need to more carefully review the `[OPTION]`s in this file, as you'll also need to change the certificate location to match the domain name you requested. Consider taking a look at the `[OPTION]`s and `[WARNING]`s in other linked config files.

```bash
sudo cp /etc/nginx/sites-available/bubbly_https.conf /etc/nginx/sites-available/example.com_https.conf
sudo nano /etc/nginx/sites-available/example.com_https.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo ln -s /etc/nginx/sites-available/example.com_https.conf /etc/nginx/sites-enabled/example.com_https.conf
sudo nginx -t && sudo service nginx reload
```

Keep `example.com_http.conf` symlinked in `sites-enabled/` permanently. It handles all HTTP traffic (including ACME renewal challenges) so that certificate renewals keep working even if the certificate has already expired.

## Optional: shared session ticket keys

Nginx 1.23.2 and newer generate TLS session ticket keys themselves and rotate them periodically, storing them in the shared session cache, so there is nothing to set up. You only need a key of your own if you run **several Nginx instances behind a load balancer** that have to resume each other's tickets.

```bash
~/Bubbly/bubbly_generate-tickets.sh
```

Then uncomment `ssl_session_ticket_key` in `/etc/nginx/conf.d/bubbly_ssl.conf` and reload. Run the script again whenever you want to rotate: it moves the existing key to `ticket.old.key` and writes a fresh one, so tickets already issued keep working. Nginx encrypts with the first key listed and decrypts with any of them, so keep the new one on top. Both files are written `600` — the key decrypts session tickets, so anyone able to read it can decrypt captured resumed sessions.

Whether or not you use an explicit key, every site shares one session cache, and on Nginx 1.23.2 and newer the automatic ticket keys live in that cache. So a session begun on one of your sites can be resumed against another. That is usually what you want across sites you own, but it does mean one site's TLS settings are not a boundary around it — a site needing its own boundary declares its own `ssl_session_cache` with a different zone name in its server block.

---

![Screenshot of SSLLabs.com](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_ssllabs.com.png)

![Screenshot of SecurityHeaders.io](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_securityheaders.io.png)
