# Configuring Let's Encrypt with Nginx
If you want an A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/index.html), then this is what you'll need to do. We assume you have already installed [Let's Encrypt](https://letsencrypt.org/) and are ready to retrieve your certificates

0. Install `git` if you haven't already.
1. `git clone https://github.com/letsencrypt/letsencrypt`
2. Upload all the files (the `letsencrypt` folders should overlap, and they expect to be in your home folder, as does the `.bash_aliases` file).
3. Execute `./Generate.sh` (you may need to mark it as executable first with `chmod 755 Generate.sh`. As it will warn, this will take a while. Have a seat.
4. When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, replace the instances of `$server_name` in `nginx.conf` with your actual domain name.
5. Now it's time to get your certificates with `renew-ssl example.com` It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds.
6. Optional: Pick a cipher list. We default to [Mozilla's Recommendation for Modern Browsers](https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=nginx-2.2.15&openssl=1.0.1e&hsts=yes&profile=modern), but leaving `TLSv1` enabled. If you want 100% in all caegories, you'll need to enable the first cipher list (and disable the other), plus remove `TLSv1` and `TLSv1.1` from the protocols line.
7. All that's left is to either move or symlink to your Nginx configuration, before testing it with `sudo nginx -t` and reloading the configuration with `sudo service nginx restart`
10. Profit (or not, it's free, who cares!)

![Screenshot from 2015-11-05 04:16:13.png](https://github.com/lewisgoddard/letsencrypt-with-nginx/raw/master/Screenshot from 2015-11-05 04:16:13.png "Screenshot from 2015-11-05 04:16:13.png")
