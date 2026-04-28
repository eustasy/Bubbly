#!/bin/bash
sudo mkdir -p /etc/nginx/ssl &&
sudo openssl rand -out /etc/nginx/ssl/ticket.key 80