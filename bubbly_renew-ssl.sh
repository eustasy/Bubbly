#!/bin/bash
# Issues or re-issues certificates with Certbot, answering the ACME challenge
# from the webroot Nginx serves in location/bubbly_well-known-passthrough.conf.
#
# This is deliberately the forceful path. It always passes --force-renew, because
# someone running this by hand wants a certificate now: a first issuance, a name
# added, a different key type, or recovery from one that is broken. Routine
# renewal is not this script's job — Certbot installs a systemd timer that runs
# `certbot renew` twice a day, reissuing only when a certificate is close to
# expiring, and the --deploy-hook below reloads Nginx when it does.
#
# [WARNING] Let's Encrypt allows 5 certificates per exact same set of identifiers
# every 7 days, refilling one every 34 hours, and that particular limit cannot be
# raised on request. Forcing the same set of names more than a few times in a week
# will lock you out until it refills. Rehearse with --dry-run, which uses the
# staging environment and is not rate limited.
#
# [OPTION] Pass --cert-name to fix a lineage's name. Certbot otherwise names it
# after the first -d, so changing the list of names later can leave you with
# example.com-0001 sitting beside example.com.
set -eu

# Deliberately not under /tmp. Any local user or process — including a
# compromised PHP application running as www-data — can create a directory there
# before root does and thereby own it, and whoever owns this directory can place
# files under /.well-known/acme-challenge/. That is enough to answer an ACME
# challenge and be issued a certificate for any name pointing at this machine.
# /var/lib is writable by root alone.
WEBROOT=/var/lib/bubbly-authenticator

sudo mkdir -p "$WEBROOT"
sudo chmod 755 "$WEBROOT"

sudo certbot certonly \
    --key-type ecdsa \
    --elliptic-curve secp384r1 \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --authenticator webroot \
    --webroot-path="$WEBROOT" \
    --deploy-hook "service nginx reload" \
    --agree-tos \
    --force-renew \
    "$@"
