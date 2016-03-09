renew-ssl() {
	mkdir -p /tmp/letsencrypt-eustasy
	~/letsencrypt/letsencrypt-auto certonly --config ~/letsencrypt-with-nginx/cli.ini --server https://acme-v01.api.letsencrypt.org/directory -a webroot --webroot-path=/tmp/letsencrypt-eustasy --agree-tos --force-renew "$@"
	sudo service nginx reload
}
