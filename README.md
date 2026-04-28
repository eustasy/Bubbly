# Bubbly

*For configuring Certbot with Nginx as quickly and securely as possible.*

If you want an instant A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html?d=lewisgoddard.me.uk) and A score on [SecurityHeaders.io](https://securityheaders.io/?q=lewisgoddard.me.uk&followRedirects=on), then this is what you'll need to do. You won't need any familiarity with [Certbot](https://github.com/certbot/certbot), [Let's Encrypt](https://letsencrypt.org/), the ACME spec, or SSL in general, just basic Nginx configuration.

**1. Install Certbot and Clone Bubbly**

We'll start off by cloning the project into the home folder with git.

```bash
cd &&
sudo apt install git certbot &&
git clone https://github.com/eustasy/Bubbly
```

**2. Generate Statics**

Generate the static keys once per server.

```bash
~/Bubbly/bubbly_generate-tickets.sh
```

As it will warn, this might take a while.

Have a seat.

**3. Copy config blocks**

When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, copy the Nginx configuration over to the Nginx area.

```bash
~/Bubbly/bubbly_copy-configs.sh
```

**4. Configure & Enable Verification**

Copy the verification site template and replace the instances of `example.com` in the file with your actual domain name.

```bash
sudo cp /etc/nginx/sites-available/bubbly_verify.conf /etc/nginx/sites-available/example.com.conf
sudo nano /etc/nginx/sites-available/example.com.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo ln -s /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-enabled/example.com.conf
sudo nginx -t && sudo service nginx reload
```

Alternatively, you can simply add `include location/bubbly_well-known-passthrough.conf;` to an existing site you want to continue working while we upgrade.


**5. Fetch Certificates**

Fetch your certificates like this:

```bash
~/Bubbly/bubbly_renew-ssl.sh -d example.com -d www.example.com
```

It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds.

Certbot will set up a systemd timer that runs `certbot renew` automatically twice a day. The `--deploy-hook` passed by the script is stored in `/etc/letsencrypt/renewal/example.com.conf`, so Nginx will be reloaded automatically after each successful renewal — no cron job or manual renewal needed.

**6. Start using the Certificates**

Remove the verification config you just made, and replace it with a live version of the site. You'll need to more carefully review the `[OPTION]`s in this file, as you'll also need to change the certificate location to match the domain name you requested. Consider taking a look at the `[OPTION]`s and `[WARNING]`s in other linked config files.

```bash
sudo rm /etc/nginx/sites-available/example.com.conf
sudo cp /etc/nginx/sites-available/bubbly_live.conf /etc/nginx/sites-available/example.com.conf
sudo nano /etc/nginx/sites-available/example.com.conf
```

Use `Ctrl` and `\` to initiate a search and replace for `example.com` with your domain.

```bash
sudo nginx -t && sudo service nginx reload
```

---

![Screenshot of SSLLabs.com](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_ssllabs.com.png)

![Screenshot of SecurityHeaders.io](https://raw.githubusercontent.com/eustasy/Bubbly/master/screenshot_securityheaders.io.png)
