# Bubbly

*For configuring Certbot with Nginx as quickly and securely as possible.*

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

## 1. Install Certbot and Clone Bubbly

We'll start off by cloning the project into the home folder with git.

```bash
cd &&
sudo apt install git certbot &&
git clone https://github.com/eustasy/Bubbly
```

## 2. Generate Statics

Generate the static keys once per server.

```bash
~/Bubbly/bubbly_generate-tickets.sh
```

As it will warn, this might take a while.

Have a seat.

## 3. Copy config blocks

When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, copy the Nginx configuration over to the Nginx area.

```bash
~/Bubbly/bubbly_copy-configs.sh
```

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

---

![Screenshot of SSLLabs.com](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_ssllabs.com.png)

![Screenshot of SecurityHeaders.io](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_securityheaders.io.png)
