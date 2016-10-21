#!/bin/bash
sudo mkdir -p /etc/nginx/ssl &&
sudo openssl rand 48 -out /etc/nginx/ssl/ticket.key &&
sudo openssl dhparam -out /etc/nginx/ssl/dhparam4.pem 4096
