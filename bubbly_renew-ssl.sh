#!/bin/bash

mkdir -p /tmp/bubbly-authenticator

~/certbot/certbot-auto certonly \
	--rsa-key-size 3072 \
	--server https://acme-v02.api.letsencrypt.org/directory \
	--authenticator webroot \
	--webroot-path=/tmp/bubbly-authenticator \
	--agree-tos \
	--force-renew \
	"$@"

sudo service nginx reload
