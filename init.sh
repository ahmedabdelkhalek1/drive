#! /usr/bin/env bash
set -e

# Expect MARIADB_HOST, MARIADB_ROOT_PASSWORD, REDIS_HOST, REDIS_PORT, ADMIN_PASSWORD
: "${MARIADB_HOST:?Set MARIADB_HOST}"
: "${MARIADB_ROOT_PASSWORD:?Set MARIADB_ROOT_PASSWORD}"
: "${REDIS_HOST:?Set REDIS_HOST}"
: "${REDIS_PORT:=6379}"
: "${ADMIN_PASSWORD:=DriveAdmin!123}"

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
  echo "Bench already exists, starting"
  cd frappe-bench
  bench start
  exit 0
fi

# Initialize bench pinned to Frappe v15
bench init --skip-redis-config-generation frappe-bench --version version-15

cd frappe-bench

# Install Drive app
bench get-app drive --branch main

# Create site (uses MariaDB root password)
bench new-site drive.localhost \
  --force \
  --mariadb-root-password "${MARIADB_ROOT_PASSWORD}" \
  --admin-password "${ADMIN_PASSWORD}" \
  --no-mariadb-socket

# Configure DB host and Redis endpoints via site/global config
bench --site drive.localhost set-config db_host "${MARIADB_HOST}"
bench set-config -g redis_cache "redis://${REDIS_HOST}:${REDIS_PORT}"
bench set-config -g redis_queue "redis://${REDIS_HOST}:${REDIS_PORT}"
bench set-config -g redis_socketio "redis://${REDIS_HOST}:${REDIS_PORT}"

# Install the Drive app into the site
bench --site drive.localhost install-app drive
bench --site drive.localhost clear-cache
bench use drive.localhost

# Start bench (serves on port 8000)
bench start
