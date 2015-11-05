sudo service nginx stop &&
~/letsencrypt/letsencrypt-auto certonly --agree-dev-preview --server https://acme-v01.api.letsencrypt.org/directory --standalone -d lewisgoddard.me.uk &&
sudo service nginx start
