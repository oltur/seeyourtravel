#!/bin/bash
# A second copy of the web container for tests: http://127.0.0.1:8089, always in local mode (everybody is the administrator).
# It uses the same files and database as the public site (http://localhost:8088) but does not touch Web.config, so tests no longer
# switch the public site into local mode. It is reachable from this computer only.
#   tools/test_site.sh start | stop | restart
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "${1:-start}" in
  stop) docker rm -f syt-web-test >/dev/null 2>&1 || true ;;
  start|restart)
    docker rm -f syt-web-test >/dev/null 2>&1 || true
    docker run -d --name syt-web-test --network syt -p 127.0.0.1:8089:8080 -e SYT_FORCE_LOCAL=1 \
      -v "$REPO/web":/app -w /app syt-web:latest xsp4 --port 8080 --address 0.0.0.0 --root /app --nonstop >/dev/null
    until curl -s -o /dev/null -f http://127.0.0.1:8089/favicon.ico; do sleep 1; done
    echo "test site: http://127.0.0.1:8089" ;;
esac
