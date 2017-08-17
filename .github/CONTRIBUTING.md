# Contributing

TODO

## Making Changes

TODO

### Filing an Issue

TODO

### Creating a Pull Request

TODO

## Current State

TODO

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

`ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';`

#### [DEFAULT] [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) using the setting "Nginx for Modern Browsers".

Modern, no XP, secure.

- Grade A (A+ with HSTS at >= 6 Months)
- 90 % Security
- Medium Compatibility
- - No Java 6 (No DH parameters > 1024 bits)
- - No IE on XP
- Robust Forward Secrecy

`ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';`

#### [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/) using the setting "Nginx for Intermediate Browsers"

Intermediate, no IE <= 6, less secure.

- Grade A-
- 90 % Security
- High Compatibility
- - No Java 6 (No DH parameters > 1024 bits)
- - No IE 6
- Some Forward Secrecy

`ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';`

### Headers

Various headers are delivered from various configuration files. This list should help source any undesired headers you see being sent. Some headers can be sent from multiple locations.

- [`nginx-config/directive/bubbly_security-headers.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/bubbly_security-headers.conf)
- - `Access-Control-Allow-Origin`
- - `X-Content-Type-Options`
- - `Frame-Options`
- - `X-Frame-Options`
- - `X-XSS-Protection`
- [`nginx-config/location/h5bp_expires.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/location/h5bp_expires.conf)
- - `Cache-Control`
- [`nginx-config/directive/h5bp_x-ua-compatible.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/h5bp_x-ua-compatible.conf)
- - `X-UA-Compatible`
- [`nginx-config/directive/h5bp_no-transform.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/h5bp_no-transform.conf)
- - `Cache-Control`
- [`nginx-config/location/h5bp_cross-domain-fonts.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/location/h5bp_cross-domain-fonts.conf)
- - `Cache-Control`
- [`nginx-config/location/bubbly_extensionless-php.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/location/bubbly_extensionless-php.conf)
- - `X-Powered-By`
- [`nginx-config/directive/bubbly_rock-hard-ssl.conf`](https://github.com/eustasy/bubbly/blob/master/nginx-config/directive/bubbly_rock-hard-ssl.conf)
- - `Strict-Transport-Security`

## Contact Points

For any security concerns arising from the state of this repository, please contact [security@eustasy.org](mailto:security@eustasy.org)
