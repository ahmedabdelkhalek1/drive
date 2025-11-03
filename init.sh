#! /usr/bin/env bash
set -e

# Expect MARIADB_HOST, MARIADB_ROOT_PASSWORD, REDIS_HOST, REDIS_PORT, ADMIN_PASSWORD
: "${MARIADB_HOST:?Set MARIADB_HOST}"
: "${MARIADB_ROOT_PASSWORD:?Set MARIADB_ROOT_PASSWORD}"
: "${REDIS_HOST:?Set REDIS_HOST}"
: "${REDIS_PORT:=6379}"
: "${ADMIN_PASSWORD:=DriveAdmin!123}"

# Reuse existing bench if present (thanks to the persistent disk)
if [ -d "/workspace/frappe-bench/apps/frappe" ]; then
  echo "Bench already exists, starting"
  cd /workspace/frappe-bench
  bench start
  exit 0
fi

# Initialize bench pinned to Frappe v15
bench init --skip-redis-config-generation /workspace/frappe-bench --version version-15

cd /workspace/frappe-bench

# Install Drive app (idempotent: if present, bench will skip)
if [ ! -d "apps/drive" ]; then
  bench get-app drive --branch main
fi

# Point bench to Render’s services
bench set-mariadb-host "${MARIADB_HOST}"
bench set-redis-cache-host "${REDIS_HOST}:${REDIS_PORT}"
bench set-redis-queue-host "${REDIS_HOST}:${REDIS_PORT}"
bench set-redis-socketio-host "${REDIS_HOST}:${REDIS_PORT}"

# Create site (demo credentials), then install Drive
if [ ! -d "sites/drive.localhost" ]; then
  bench new-site drive.localhost \
    --force \
    --mariadb-root-password "${MARIADB_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" \
    --no-mariadb-socket
  bench --site drive.localhost install-app drive
fi

bench --site drive.localhost clear-cache
bench use drive.localhost

# Start bench (serves on 0.0.0.0:8000)
bench start
