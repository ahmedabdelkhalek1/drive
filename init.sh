#! /usr/bin/env bash
set -e

# Expect MARIADB_HOST, MARIADB_ROOT_PASSWORD, REDIS_HOST, REDIS_PORT, and ADMIN_PASSWORD
: "${MARIADB_HOST:?Set MARIADB_HOST}"
: "${MARIADB_ROOT_PASSWORD:?Set MARIADB_ROOT_PASSWORD}"
: "${REDIS_HOST:?Set REDIS_HOST}"
: "${REDIS_PORT:=6379}"
: "${ADMIN_PASSWORD:=admin}"

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
  echo "Bench already exists, starting"
  cd frappe-bench
  bench start
  exit 0
fi

# Initialize bench pinned to Frappe v15
bench init --skip-redis-config-generation frappe-bench --version version-15

cd frappe-bench

# Point bench to Render’s services
bench set-mariadb-host "${MARIADB_HOST}"
bench set-redis-cache-host "${REDIS_HOST}:${REDIS_PORT}"
bench set-redis-queue-host "${REDIS_HOST}:${REDIS_PORT}"
bench set-redis-socketio-host "${REDIS_HOST}:${REDIS_PORT}"

# Remove dev-only processes from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

# Get Drive and create site
bench get-app drive --branch main
bench new-site drive.localhost \
  --force \
  --mariadb-root-password "${MARIADB_ROOT_PASSWORD}" \
  --admin-password "${ADMIN_PASSWORD}" \
  --no-mariadb-socket

bench --site drive.localhost install-app drive
bench --site drive.localhost set-config developer_mode 1
bench --site drive.localhost clear-cache
bench --site drive.localhost set-config mute_emails 1
bench use drive.localhost

# Start bench on port 8000
bench start
