#!/bin/bash

VIKUNJA_API_URL="${VIKUNJA_API_URL:-"https://tasks.silkky.cloud/api/v1"}"

echo "Using $VIKUNJA_API_URL as the API address"

# Escape the variable to prevent sed from complaining
VIKUNJA_API_URL=$(echo $VIKUNJA_API_URL |sed 's/\//\\\//g')

sed -i "s/http\:\/\/localhost\:3456//g" /usr/share/caddy/index.html
sed -i "s/'\/api\/v1/'$VIKUNJA_API_URL/g" /usr/share/caddy/index.html

sleep 2s

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile