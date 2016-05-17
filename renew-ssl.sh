#!/bin/bash
mkdir -p /tmp/certbot-with-nginx
~/certbot/certbot-auto certonly --config ~/certbot-with-nginx/cli.ini --server https://acme-v01.api.letsencrypt.org/directory -a webroot --webroot-path=/tmp/certbot-with-nginx --agree-tos --force-renew "$@"
sudo service nginx reload
