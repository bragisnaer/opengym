#!/bin/sh
set -e
mkdir -p /data
# API first. nginx only starts once /api/health answers, so a fresh machine never serves 502.
(cd /app && node server.js; echo "api exited, restarting machine"; kill 1) &
i=0
until wget -q -O /dev/null http://127.0.0.1:3000/api/health; do
  i=$((i+1)); [ $i -gt 60 ] && echo "api did not come up" && exit 1
  sleep 0.5
done
exec /docker-entrypoint.sh nginx -g 'daemon off;'