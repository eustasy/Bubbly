# Contributing

We love pull requests from everyone. Check out our [open issues](https://github.com/eustasy/bubbly/issues), partically anything tagged as Bytesize, for things you can get to work on. By participating in this project, you agree to abide by the project [code of conduct](https://github.com/eustasy/bubbly/blob/master/CODE_OF_CONDUCT.md).

## Making Changes

We recommend forking the repository, and then cloning your new repo.

    git clone git@github.com:your-username/bubbly.git

Once you've made changes and committed them in your fork, preferably on a nicely named branch with descriptive commit messages, you can move on to [Creating a Pull Request](#creating-a-pull-request).

### Filing an Issue

Filing a new issue is a partially self-documenting process, as the [`.github/ISSUE_TEMPLATE.md`](https://github.com/eustasy/bubbly/blob/master/.github/ISSUE_TEMPLATE.md) file is automatically loaded to be filled out by the user.

[`File an Issue`](https://github.com/eustasy/bubbly/issues/new)

### Creating a Pull Request

Similar to Filing an Issue, Creating a Pull Request is partially self-documenting as the [`.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/eustasy/bubbly/blob/master/.github/PULL_REQUEST_TEMPLATE.md) file is automatically loaded into the system. First though, you will need to have [made the changes](#making-changes) in your fork.

[`Create a Pull Request`](https://github.com/eustasy/bubbly/compare/)

## Current State

### Cipher Sources

In [`nginx-config/directive/bubbly_rock-hard-ssl.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/bubbly_rock-hard-ssl.conf) you will find a list of three cipher suite options at the bottom. It is imperative that these are kept as up to date as possible. All were up to date as of 2017-08-17.

#### [Cipher List](https://cipherli.st)

Super-modern, probably not suitable for production, very secure.

- Grade A  (A+ with HSTS at >= 6 Months)
- 100 % Security
- Low Compatibility
- - No Android 2
- - No Java
- - No IE < 11
- Robust Forward Secrecy

```
ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
```

#### [DEFAULT] [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) using the setting "Nginx for Modern Browsers".

Modern, no XP, secure.

- Grade A (A+ with HSTS at >= 6 Months)
- 90 % Security
- Medium Compatibility
- - No Java 6 (No DH parameters > 1024 bits)
- - No IE on XP
- Robust Forward Secrecy

```
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
```

#### [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) using the setting "Nginx for Intermediate Browsers"

Intermediate, no IE <= 6, less secure.

- Grade A-
- 90 % Security
- High Compatibility
- - No Java 6 (No DH parameters > 1024 bits)
- - No IE 6
- Some Forward Secrecy

```
ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
```

### Headers

Various headers are delivered from various configuration files. This list should help source any undesired headers you see being sent. Some headers can be sent from multiple locations.

- [`nginx-config/directive/bubbly_security-headers.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/bubbly_security-headers.conf)
- - Disable versions in `Server` 
- - `Access-Control-Allow-Origin`
- - `Content-Security-Policy-Report-Only`
- - `X-Content-Security-Policy-Report-Only`
- - `Content-Security-Policy`
- - `X-Content-Security-Policy`
- - `Expect-CT`
- - `X-Content-Type-Options`
- - `Frame-Options`
- - `X-Frame-Options`
- - `Referrer-Policy`
- - `X-XSS-Protection`
- [`nginx-config/location/h5bp_expires.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/location/h5bp_expires.conf)
- - `Cache-Control`
- [`nginx-config/directive/h5bp_x-ua-compatible.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/h5bp_x-ua-compatible.conf)
- - `X-UA-Compatible`
- [`nginx-config/directive/h5bp_no-transform.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/h5bp_no-transform.conf)
- - `Cache-Control`
- [`nginx-config/location/bubbly_extensionless-php.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/location/bubbly_extensionless-php.conf)
- - Suppresses `X-Powered-By`
- [`nginx-config/directive/bubbly_rock-hard-ssl.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/bubbly_rock-hard-ssl.conf)
- - `Strict-Transport-Security`

## Contact Points

For any security concerns arising from the state of this repository, please contact [security@eustasy.org](mailto:security@eustasy.org)
