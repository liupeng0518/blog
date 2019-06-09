#!/usr/bin/env sh
set -e

export CADDY_ROOT=/root/caddy
export CADDYPATH=${CADDY_ROOT}/assets
export CADDY_WWW_ROOT=${CADDY_ROOT}/www
export CADDY_LOG_ROOT=${CADDY_ROOT}/logs
export CADDY_REPO_ROOT=${CADDY_ROOT}/repo
mkdir -p ${CADDY_WWW_ROOT}/${CADDY_DOMAIN} ${CADDY_LOG_ROOT}/${CADDY_DOMAIN}

exec "$@"