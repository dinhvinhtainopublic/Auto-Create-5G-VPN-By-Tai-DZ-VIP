#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Railway injects $PORT. We expose it to nginx
# via APP_PORT so envsubst can fill the template.
# ─────────────────────────────────────────────
export APP_PORT="${PORT:-3000}"

echo "========================================="
echo "  3x-ui + nginx on Railway"
echo "  Listening on port: $APP_PORT"
echo "========================================="

# Ensure runtime dirs exist
mkdir -p /var/lib/nginx/tmp/client_body \
         /var/lib/nginx/tmp/proxy \
         /var/log/nginx

# ── 1. Configure 3x-ui panel ─────────────────
cd /usr/local/x-ui
echo "[1/4] Applying x-ui settings (panel port 2053, path /managepanel/)..."
./x-ui setting -port 2053 -webBasePath /managepanel/ 2>/dev/null || true

# ── 2. Build nginx.conf from template ────────
echo "[2/4] Generating nginx.conf for port $APP_PORT..."
envsubst '${APP_PORT}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

# ── 3. Start x-ui in background ──────────────
echo "[3/4] Starting x-ui (panel + xray)..."
./x-ui &
XUI_PID=$!

# Wait until x-ui panel is ready (up to 30 s)
echo "      Waiting for x-ui panel on :2053..."
for i in $(seq 1 30); do
    if wget -qO- http://127.0.0.1:2053/managepanel/ >/dev/null 2>&1; then
        echo "      x-ui ready after ${i}s ✓"
        break
    fi
    sleep 1
done

# ── 4. Start nginx in foreground ─────────────
echo "[4/4] Starting nginx on port $APP_PORT..."
nginx -t
exec nginx -g "daemon off;"
