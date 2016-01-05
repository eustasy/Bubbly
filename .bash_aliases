renew-ssl() {
	mkdir -p /tmp/letsencrypt-eustasy
	~/letsencrypt/letsencrypt-auto certonly --config ~/letsencrypt-with-nginx/cli.ini --server https://acme-v01.api.letsencrypt.org/directory -a webroot --webroot-path=/tmp/letsencrypt-eustasy --agree-tos $1 $2 $3 $4 $5 $6 $7 $8 $9 $10
	sudo service nginx reload
}
