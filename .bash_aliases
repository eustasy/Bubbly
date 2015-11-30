renew-ssl() {
	sudo service nginx stop
	~/letsencrypt/letsencrypt-auto certonly --agree-dev-preview --standalone -d $1
	sudo service nginx start
}
