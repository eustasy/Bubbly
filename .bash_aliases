renew-ssl() {
	sudo service nginx stop
	~/letsencrypt/letsencrypt-auto certonly --standalone -d $1
	sudo service nginx start
}
