#!/bin/bash
# Generates a TLS session ticket key for Nginx, rotating any existing one.
#
# You probably do not need this. Nginx 1.23.2 and newer generate ticket keys
# themselves and rotate them periodically in the shared session cache, which is
# better than one static key. An explicit key is only needed when several Nginx
# instances behind a load balancer have to resume each other's tickets.
#
# After running this, uncomment the ssl_session_ticket_key lines in
# /etc/nginx/conf.d/bubbly_ssl.conf and reload Nginx.
set -eu

KEY_DIR=/etc/nginx/ssl
KEY="$KEY_DIR/ticket.key"
KEY_OLD="$KEY_DIR/ticket.old.key"

sudo mkdir -p "$KEY_DIR"
# The key decrypts session tickets, so anyone who can read it can decrypt
# captured resumed sessions. Only root needs it: Nginx reads the file as the
# master process when the config loads, never as a worker.
sudo chmod 700 "$KEY_DIR"

# Rotate rather than overwrite. Nginx encrypts with the first key it is given
# and can still decrypt with the rest, so keeping the previous one means tickets
# already issued survive the reload.
if sudo test -f "$KEY"; then
    sudo mv -f "$KEY" "$KEY_OLD"
    sudo chmod 600 "$KEY_OLD"
    echo "Rotated the previous key to $KEY_OLD"
fi

sudo openssl rand -out "$KEY" 80
sudo chmod 600 "$KEY"

echo "Wrote a new 80-byte key to $KEY"
echo
echo "Nginx encrypts with the first ssl_session_ticket_key listed and decrypts"
echo "with any of them, so list the new key first:"
echo "    ssl_session_ticket_key $KEY;"
if sudo test -f "$KEY_OLD"; then
    echo "    ssl_session_ticket_key $KEY_OLD;"
fi
echo
echo "Then: sudo nginx -t && sudo service nginx reload"
