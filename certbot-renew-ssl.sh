#!/bin/bash

mkdir -p /tmp/certbot-with-nginx

~/certbot/certbot-auto certonly \
	--rsa-key-size 4096 \
	--server https://acme-v01.api.letsencrypt.org/directory \
	--authenticator webroot \
	--webroot-path=/tmp/certbot-with-nginx \
	--agree-tos \
	--force-renew \
	"$@"

sudo service nginx reload
