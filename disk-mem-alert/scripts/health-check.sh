#!/usr/bin/env bash
set -euo pipefail

# ===== Settings (edit if needed) =====
DISK_WARN=80
DISK_CRIT=90

MEM_WARN=20   # percent available
MEM_CRIT=10

LOG_FILE="/home/$USER/portfolio/linux-projects/disk-mem-alert/logs/health-check.log"

# Slack webhook (optional)
# Export it in your shell or store it in /etc/default/disk-mem-alert
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

HOST="$(hostname -f 2>/dev/null || hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

log() {
  echo "[$DATE] $*" | tee -a "$LOG_FILE"
}

send_slack() {
  local msg="$1"
  if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    log "Slack webhook not set. Skipping Slack alert."
    return 0
  fi

  curl -sS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$msg\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || true
}

# ===== Disk Check =====
# checks root filesystem; you can add more mounts if needed
DISK_USED="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"

# ===== Memory Check =====
# available % = MemAvailable / MemTotal * 100
MEM_TOTAL_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
MEM_AVAIL_KB="$(awk '/MemAvailable/ {print $2}' /proc/meminfo)"
MEM_AVAIL_PCT="$(awk -v a="$MEM_AVAIL_KB" -v t="$MEM_TOTAL_KB" 'BEGIN {printf "%.0f", (a/t)*100}')"

# ===== Decide status =====
STATUS="OK"
ALERTS=()

if (( DISK_USED >= DISK_CRIT )); then
  STATUS="CRITICAL"
  ALERTS+=("Disk CRITICAL: / is ${DISK_USED}% used (>= ${DISK_CRIT}%)")
elif (( DISK_USED >= DISK_WARN )); then
  STATUS="WARNING"
  ALERTS+=("Disk WARNING: / is ${DISK_USED}% used (>= ${DISK_WARN}%)")
fi

if (( MEM_AVAIL_PCT <= MEM_CRIT )); then
  STATUS="CRITICAL"
  ALERTS+=("Memory CRITICAL: ${MEM_AVAIL_PCT}% available (<= ${MEM_CRIT}%)")
elif (( MEM_AVAIL_PCT <= MEM_WARN )); then
  [[ "$STATUS" == "OK" ]] && STATUS="WARNING"
  ALERTS+=("Memory WARNING: ${MEM_AVAIL_PCT}% available (<= ${MEM_WARN}%)")
fi

# ===== Details for troubleshooting =====
TOP_MEM="$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 8 | sed 's/"/'\''/g')"
BIG_DIRS="$(sudo du -xh /var 2>/dev/null | sort -h | tail -n 8 | sed 's/"/'\''/g' || true)"

if [[ ${#ALERTS[@]} -eq 0 ]]; then
  log "OK - Disk: ${DISK_USED}% used, MemAvailable: ${MEM_AVAIL_PCT}%"
  exit 0
fi

MESSAGE="[$STATUS] $HOST | ${ALERTS[*]}
Disk: / ${DISK_USED}% used
MemAvailable: ${MEM_AVAIL_PCT}%

Top memory processes:
$TOP_MEM

Biggest /var dirs:
$BIG_DIRS
"

log "$MESSAGE"
send_slack "$(echo "$MESSAGE" | head -c 2900)"  # Slack message size safety