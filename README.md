# Configuring Certbot with Nginx
If you want an A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/index.html), then this is what you'll need to do. You won't need any familiarity with [Certbot](https://github.com/certbot/certbot), [Let's Encrypt](https://letsencrypt.org/), the ACME spec, or SSL in general, just basic Nginx configuration.

0. Install `git` if you haven't already.
1. `git clone https://github.com/certbot/certbot`
2. `git clone https://github.com/eustasy/certbot-with-nginx`
3. Execute `~/certbot-with-nginx/Generate.sh` (you may need to mark it as executable first with `chmod 755 ~/certbot-with-nginx/Generate.sh`). As it will warn, this will take a while. Have a seat.
4. When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, replace the instances of `example.com` in `*.conf` and `crontab` with your actual domain name. Also take a look at the `[OPTION]`s and `[WARNING]`s.
5. Now we need to link in the `nginx.verify.conf`, test it, and reload: `sudo ln -s ~/certbot-with-nginx/nginx.verify.conf /etc/nginx/sites-enabled/nginx.verify.conf && sudo nginx -t && sudo service nginx reload` Alternatively, you can simply copy the location block from `nginx.verify.conf`, if you want an existing site to continue working.
6. Now it's time to get your certificates with `~/certbot-with-nginx/renew-ssl.sh -d example.com -d www.example.com` It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds. Sub-domains will just be `~/certbot-with-nginx/renew-ssl.sh -d sub.example.com`
7. Now we need to link in the actual site, test it, and reload: `sudo rm /etc/nginx/sites-enabled/nginx.verify.conf && sudo ln -s ~/certbot-with-nginx/nginx.conf /etc/nginx/sites-enabled/nginx.conf && sudo nginx -t && sudo service nginx reload`
8. Install the edited `crontab` for automatic renewal. `cat ~/certbot-with-nginx/crontab > /tmp/le-crontab; crontab -l >> /tmp/le-crontab && crontab /tmp/le-crontab`

![Screenshot from 2015-11-05 04:16:13.png](https://raw.githubusercontent.com/eustasy/certbot-with-nginx/master/Screenshot%20from%202015-11-05%2004%3A16%3A13.png "Screenshot from 2015-11-05 04:16:13.png")
