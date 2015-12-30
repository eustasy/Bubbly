# Configuring Let's Encrypt with Nginx
If you want an A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/index.html), then this is what you'll need to do. We assume you have already installed [Let's Encrypt](https://letsencrypt.org/) and are ready to retrieve your certificates

0. Install `git` if you haven't already.
1. `git clone https://github.com/letsencrypt/letsencrypt`
2. Upload all the files (the `letsencrypt` folders should overlap, and they expect to be in your home folder, as does the `.bash_aliases` file).
3. Execute `./Generate.sh` (you may need to mark it as executable first with `chmod 755 Generate.sh`. As it will warn, this will take a while. Have a seat.
4. When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, replace the instances of `example.com` in `nginx.conf` with your actual domain name. Optionally: edit `nginx.verify-and-redirect.conf` so it doesn't respond to every domain if you have hosts you don't want to be using Let's Encrypt.
5. Optional: Pick a cipher list. We default to [Mozilla's Recommendation for Modern Browsers](https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=nginx-2.2.15&openssl=1.0.1e&hsts=yes&profile=modern), but leaving `TLSv1` enabled. If you want 100% in all caegories, you'll need to enable the first cipher list (and disable the other), plus remove `TLSv1` and `TLSv1.1` from the protocols line.
6. Now we need to link in those: `sudo ln -s nginx.verify-and-redirect.conf /etc/nginx/sites-enabled/nginx.verify-and-redirect.conf; sudo ln -s nginx.conf /etc/nginx/sites-enabled/nginx.conf; sudo service nginx reload`
7. Now it's time to get your certificates with `renew-ssl -d example.com -d www.example.com` It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds. Sub-domains will just be `renew-ssl -d sub.example.com`
8. Edit the `crontab` file to match your domains, and install it for automatic renewal. `cat crontab > /tmp/le-crontab; crontab -l >> /tmp/le-crontab; crontab /tmp/le-crontab`
9. Profit (or not, it's free, who cares!)

![Screenshot from 2015-11-05 04:16:13.png](https://github.com/lewisgoddard/letsencrypt-with-nginx/raw/master/Screenshot from 2015-11-05 04:16:13.png "Screenshot from 2015-11-05 04:16:13.png")
