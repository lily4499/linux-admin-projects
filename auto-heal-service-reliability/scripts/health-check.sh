#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="demo-web.service"
URL="http://localhost:8080"
PORT="8080"

LOG_DIR="/var/log/auto-heal"
LOG_FILE="${LOG_DIR}/auto-heal.log"

mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 0644 "${LOG_FILE}"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

log() {
  echo "$(ts) | ${1}" | tee -a "${LOG_FILE}" >/dev/null
}

is_systemd_active() {
  systemctl is-active --quiet "${SERVICE_NAME}"
}

is_port_listening() {
  timeout 2 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${PORT}" >/dev/null 2>&1
}

is_http_ok() {
  local code
  code="$(curl -sS -o /dev/null -m 2 -w "%{http_code}" "${URL}" || true)"
  [[ "${code}" =~ ^2|^3 ]]
}

restart_service() {
  log "UNHEALTHY | restarting ${SERVICE_NAME}"
  systemctl restart "${SERVICE_NAME}"
  sleep 2

  if is_systemd_active && is_port_listening && is_http_ok; then
    log "RECOVERED | ${SERVICE_NAME} is healthy after restart"
    exit 0
  else
    log "FAILED | ${SERVICE_NAME} still unhealthy after restart"
    exit 1
  fi
}

main() {
  if is_systemd_active && is_port_listening && is_http_ok; then
    log "OK | ${SERVICE_NAME} healthy (systemd=active, port=${PORT}, http=ok)"
    exit 0
  fi

  restart_service
}

main "$@"