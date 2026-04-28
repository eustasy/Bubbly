#!/bin/bash

sudo mkdir -p /tmp/bubbly-authenticator

sudo certbot certonly \
	--key-type ecdsa \
	--elliptic-curve secp384r1 \
	--server https://acme-v02.api.letsencrypt.org/directory \
	--authenticator webroot \
	--webroot-path=/tmp/bubbly-authenticator \
	--agree-tos \
	"$@"

sudo service nginx reload
