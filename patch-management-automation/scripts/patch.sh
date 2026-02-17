#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/var/log/patching"
TS="$(date +%F_%H%M%S)"
LOG_FILE="${LOG_DIR}/patch_${TS}.log"
REPORT_FILE="${LOG_DIR}/report_${TS}.txt"

sudo mkdir -p "${LOG_DIR}"

echo "===== PATCH START: ${TS} =====" | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Host:" | tee -a "${LOG_FILE}"
hostnamectl | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Kernel (before):" | tee -a "${LOG_FILE}"
uname -r | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Available updates (before):" | tee -a "${LOG_FILE}"
sudo apt-get update -y | tee -a "${LOG_FILE}"
apt list --upgradable 2>/dev/null | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Applying patches:" | tee -a "${LOG_FILE}"
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Removing unused packages:" | tee -a "${LOG_FILE}"
sudo apt-get autoremove -y | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Updated packages installed (summary):" | tee -a "${LOG_FILE}"
grep -E "Setting up|Unpacking|Preparing to unpack" "${LOG_FILE}" | tail -n 60 | tee -a "${LOG_FILE}" || true

echo "" | tee -a "${LOG_FILE}"
echo ">>> Kernel (after):" | tee -a "${LOG_FILE}"
uname -r | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo ">>> Reboot required?" | tee -a "${LOG_FILE}"
if [ -f /var/run/reboot-required ]; then
  echo "YES - reboot required" | tee -a "${LOG_FILE}"
else
  echo "NO - reboot not required" | tee -a "${LOG_FILE}"
fi

echo "" | tee -a "${LOG_FILE}"
echo "===== PATCH END: ${TS} =====" | tee -a "${LOG_FILE}"

# Short “report” file (easy for quick review)
{
  echo "Patch Report - ${TS}"
  echo "Host: $(hostname)"
  echo "Kernel: $(uname -r)"
  if [ -f /var/run/reboot-required ]; then
    echo "Reboot required: YES"
  else
    echo "Reboot required: NO"
  fi
  echo "Log file: ${LOG_FILE}"
} | sudo tee "${REPORT_FILE}" >/dev/null

exit 0
