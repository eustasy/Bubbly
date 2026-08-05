---
name: tls-per-vhost-findings
description: Measured on nginx 1.26 and 1.28 with OpenSSL 3.5 — per-vhost ssl_ciphers does apply, but ssl_protocols and ssl_ecdh_curve are taken from the default server for the listening socket.
metadata:
  type: project
---

Measured 2026-08-05 by the runtime TLS probe in `.github/workflows/nginx.yml` (CI run 31038599135), on three vhosts sharing `0.0.0.0:443`. Results were **identical on Debian 13 / nginx 1.26.3 / OpenSSL 3.5.6 and Ubuntu 26.04 / nginx 1.28.3 / OpenSSL 3.5.5**, so this is not version-specific across the supported range.

The test vhost `beta.test` was given values wholly disjoint from the default server's — `ssl_protocols TLSv1.3;`, `ssl_ciphers ECDHE-ECDSA-AES256-SHA384;`, `ssl_ecdh_curve prime256v1;` — so whichever set it negotiated identified the winning block.

| Directive | Per-vhost? | Evidence |
|---|---|---|
| `ssl_protocols` | **No** — default server wins | beta.test accepted a TLS 1.2 handshake despite asking for TLS 1.3 only |
| `ssl_ciphers` | **Yes** | that TLS 1.2 handshake negotiated `ECDHE-ECDSA-AES256-SHA384`, beta's lone cipher, not the default server's GCM/ChaCha list |
| `ssl_ecdh_curve` | **No** — default server wins | TLS 1.3 to beta.test negotiated `X25519MLKEM768`, not `prime256v1` |

This matches the documented reason for `ssl_protocols` (the protocol list is fixed by OpenSSL before SNI selects a server) and extends it: key-exchange group selection happens at the same stage, whereas the TLS 1.2 cipher is chosen after the SNI callback has swapped the `SSL_CTX`, so the per-vhost list is in force by then.

**Consequences for [[multisite-refactor-plan]] item C:**

- Per-site TLS *profiles* in the Mozilla sense are not achievable on one socket. A site cannot be TLS 1.3-only while its neighbour allows 1.2, and cannot choose its own groups. Genuinely different profiles need separate listen sockets — a distinct IP or port.
- Per-site `ssl_ciphers` does work, but only bites on TLS 1.2, since `ssl_ciphers` never governs TLS 1.3 ciphersuites (those need `ssl_conf_command Ciphersuites=…`, available at this floor but subject to the same SNI-timing caveat and unmeasured).
- Which server is "the default" is accidental today. With no `default_server` flag in any template, the probe found that a connection with **no SNI is served `alpha.test`'s certificate** — the alphabetically-first `sites-enabled` file, whose first block is merely the `www`→apex redirect. That block therefore dictates protocols and groups for every site on the box, and onboarding a site sorting earlier silently changes them.

**Harness note.** These probes must write each handshake to a file and grep the file, never pipe openssl into `grep -q`. GitHub runs `shell: bash` as `bash -e -o pipefail`, under which `grep -q` exiting on its first match kills openssl with SIGPIPE and fails the pipeline even though the handshake succeeded. That produced a convincing false result — a failure on Debian 13 and a pass on Ubuntu 26.04, reading exactly like an nginx 1.26 versus 1.28 behaviour difference, when the captured output showed both had accepted TLS 1.2. Container jobs default to `sh -e`, which has no pipefail, so the same code behaved differently before the shell was pinned to bash. Also note openssl exits non-zero when a handshake is legitimately refused, so `|| true` plus a file check is the reliable pattern.

Also observed: all three vhosts negotiated TLS 1.3 with `X25519MLKEM768`, confirming the post-quantum group is genuinely in use on both platforms. And the config-test warning is `"ssl_stapling" ignored, no OCSP responder URL in the certificate` — not the "issuer certificate not found" variant — so gating CI on `nginx -t` warnings would require test certificates carrying an `authorityInfoAccess` OCSP URI, not merely a signing CA.
