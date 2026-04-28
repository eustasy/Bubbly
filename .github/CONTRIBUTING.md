# Contributing

We love pull requests from everyone. Check out our [open issues](https://github.com/eustasy/Bubbly/issues), particularly anything tagged as Bytesize, for things you can get to work on. By participating in this project, you agree to abide by the project [code of conduct](https://github.com/eustasy/Bubbly/blob/master/.github/CODE_OF_CONDUCT.md).

## Making Changes

We recommend forking the repository, and then cloning your new repo.

    git clone git@github.com:your-username/bubbly.git

Once you've made changes and committed them in your fork, preferably on a nicely named branch with descriptive commit messages, you can move on to [Creating a Pull Request](#creating-a-pull-request).

### Filing an Issue

Filing a new issue is a partially self-documenting process, as the [`.github/ISSUE_TEMPLATE.md`](https://github.com/eustasy/Bubbly/blob/master/.github/ISSUE_TEMPLATE.md) file is automatically loaded to be filled out by the user.

[`File an Issue`](https://github.com/eustasy/Bubbly/issues/new)

### Creating a Pull Request

Similar to Filing an Issue, Creating a Pull Request is partially self-documenting as the [`.github/PULL_REQUEST_TEMPLATE.md`](https://github.com/eustasy/Bubbly/blob/master/.github/PULL_REQUEST_TEMPLATE.md) file is automatically loaded into the system. First though, you will need to have [made the changes](#making-changes) in your fork.

[`Create a Pull Request`](https://github.com/eustasy/Bubbly/compare/)

## Current State

### Cipher Sources

In [`nginx-config/directive/bubbly_rock-hard-ssl.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/directive/bubbly_rock-hard-ssl.conf) you will find two cipher suite options. It is imperative that these are kept as up to date as possible. Both are generated from the [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) (Guideline v6.0).

#### Option 1. Modern — TLS 1.3 only

Drops everything older than ~2020 browsers.

- Supports Firefox 63, Android 10.0, Chrome 70, Edge 75, Java 11, OpenSSL 1.1.1, Opera 57, Safari 12.1

```
ssl_protocols TLSv1.3;
ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1:secp384r1;
ssl_prefer_server_ciphers off;
```

#### [DEFAULT] Option 2. Intermediate — TLS 1.2 + 1.3

Supports the last several versions of every modern browser, plus a long tail.

- Supports Firefox 31.3.0, Android 4.4.2, Chrome 49, Edge 15 on Windows 10, IE 11 on Windows 10, Java 8u161, OpenSSL 1.0.1l, Opera 20, Safari 9

```
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ecdh_curve X25519MLKEM768:X25519:prime256v1:secp384r1;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;
```

### Headers

Various headers are delivered from various configuration files. This list should help source any undesired headers you see being sent. Some headers can be sent from multiple locations.

- [`nginx-config/directive/bubbly_security-headers.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/directive/bubbly_security-headers.conf)
- - `Access-Control-Allow-Origin`
- - `Content-Security-Policy-Report-Only`
- - `Content-Security-Policy`
- - `X-Content-Type-Options`
- - `X-Frame-Options`
- - `Feature-Policy`
- - `Permissions-Policy`
- - `Referrer-Policy`
- - `Server`
- - `Strict-Transport-Security`
- - `X-XSS-Protection`
- [`nginx-config/location/h5bp_expires.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/location/h5bp_expires.conf)
- - `Cache-Control`
- [`nginx-config/directive/h5bp_no-transform.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/directive/h5bp_no-transform.conf)
- - `Cache-Control`
- [`nginx-config/location/bubbly_extensionless-php.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/location/bubbly_extensionless-php.conf)
- - Suppresses `X-Powered-By`
- [`nginx-config/directive/bubbly_rock-hard-ssl.conf`](https://github.com/eustasy/Bubbly/blob/master/nginx-config/directive/bubbly_rock-hard-ssl.conf)

## Contact Points

For any security concerns arising from the state of this repository, please contact [security@eustasy.org](mailto:security@eustasy.org)
