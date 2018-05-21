#!/bin/bash
printf "WARNING: The generation of static keys and parameters may take several minutes, and will consume a considerable amount of processing power. If not favourable on a production machine, new keys can be generated elsewhere and copied over a secure connection. "
read -rsp $'Press any key to continue, or Ctrl+C to cancel...\n' -n1 key
sudo mkdir -p /etc/nginx/ssl &&
sudo openssl rand -out /etc/nginx/ssl/ticket.key 48 &&
sudo openssl dhparam -out /etc/nginx/ssl/dhparam4.pem 4096
