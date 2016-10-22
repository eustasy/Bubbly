#!/bin/bash

mkdir -p /tmp/bubbly

~/certbot/certbot-auto certonly \
	--rsa-key-size 4096 \
	--server https://acme-v01.api.letsencrypt.org/directory \
	--authenticator webroot \
	--webroot-path=/tmp/bubbly-authenticator \
	--agree-tos \
	--force-renew \
	"$@"

sudo service nginx reload
