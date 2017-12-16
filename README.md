# Bubbly

### For configuring Certbot with Nginx

[![Build Status](https://travis-ci.org/eustasy/bubbly.svg?branch=master)](https://travis-ci.org/eustasy/bubbly)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/ecf6627cc61b43d6a1b52b9991b86680)](https://www.codacy.com/app/lewisgoddard/bubbly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=eustasy/bubbly&amp;utm_campaign=Badge_Grade)
[![Code Climate](https://codeclimate.com/github/eustasy/bubbly/badges/gpa.svg)](https://codeclimate.com/github/eustasy/bubbly)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=25541893)](https://www.bountysource.com/teams/eustasy/issues?tracker_ids=25541893)

If you want an instant A+ score on Qualys [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html?d=lewisgoddard.me.uk) and A score on [SecurityHeaders.io](https://securityheaders.io/?q=lewisgoddard.me.uk&followRedirects=on), then this is what you'll need to do. You won't need any familiarity with [Certbot](https://github.com/certbot/certbot), [Let's Encrypt](https://letsencrypt.org/), the ACME spec, or SSL in general, just basic Nginx configuration.

**1. Clone Certbot and Bubbly**

We'll start off by cloning the projects into the home folder with git.

```
cd &&
sudo apt install git &&
git clone https://github.com/certbot/certbot &&
git clone https://github.com/eustasy/bubbly
```

**2. Generate Statics**

Generate the static keys once per server.

```
~/bubbly/bubbly_generate-statics.sh
```

As it will warn, this will take a while.

Have a seat.

**3. Copy config blocks**

When you've gone and made something in the 15 minutes that could well take, or you've just set up a new SSH session, copy the Nginx configuration over to the Nginx area.

```
~/bubbly/bubbly_copy-configs.sh
```

**4. Configure & Enable Verification**

Copy the verification site template and replace the instances of `example.com` in the file with your actual domain name.

```
sudo cp /etc/nginx/sites-available/bubbly_verify.conf /etc/nginx/sites-available/example.com.conf
sudo nano /etc/nginx/sites-available/example.com.conf
sudo ln -s /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-enabled/example.com.conf
sudo nginx -t && sudo service nginx reload
```

Alternatively, you can simply add `include location/bubbly_well-known-passthrough.conf;` to an existing site you want to continue working while we upgrade.


**5. Fetch Certificates**

Fetch your certificates like this:

```
~/bubbly/bubbly_renew-ssl.sh -d example.com -d www.example.com
```

It will ask for the root password, and an email address, so hang around, it shouldn't take more than a few seconds.

**6. Start using the Certificates**

Remove the verification config you just made, and replace it with a live version of the site. You'll need to more carefully review the `[OPTION]`s in this file, as you'll also need to change the certificate location to match the domain name you requested. Consider taking a look at the `[OPTION]`s and `[WARNING]`s in other linked config files.

```
sudo rm /etc/nginx/sites-available/example.com.conf
sudo cp /etc/nginx/sites-available/bubbly_live.conf /etc/nginx/sites-available/example.com.conf
sudo nano /etc/nginx/sites-available/example.com.conf
sudo nginx -t && sudo service nginx reload
```

**7. Automate Renewal**

Edit `crontab.conf` and append it to your existing cron jobs for automatic renewal. This is important, since Let's Encrypt certificates expire in three months.

```
nano ~/bubbly/crontab.conf
cat ~/bubbly/crontab.conf > /tmp/bubbly-crontab
crontab -l >> /tmp/bubbly-crontab
crontab /tmp/bubbly-crontab
```

---

![Screenshot of SSLLabs.com](https://raw.githubusercontent.com/eustasy/bubbly/master/screenshot_ssllabs.com.png)

![Screenshot of SecurityHeaders.io](https://raw.githubusercontent.com/eustasy/bubbly/master/screenshot_securityheaders.io.png)
