
# Patch Management Automation (Linux) — Automated Weekly Updates + Reporting

Goal: Regular patching with logs and controlled reboot.

> Patching is needed to **fix security holes and bugs so the server stays safe and stable**.


I built this project to **automate patching on Linux servers** so updates happen on schedule, logs are saved, and I can quickly confirm what changed (or why it failed).

---

## Problem

Manual patching is risky and inconsistent:

- Servers don’t get updated on time
- People forget or delay updates
- No clear proof of what was installed
- If a patch fails, there’s no simple history to troubleshoot

That leads to **security exposure**, **random outages**, and **stress during audits**.

---

## Solution

I automated patch management using a simple, reliable workflow:

- **Schedule patching** (example: every Sunday at 2:00 AM)
- **Run updates safely** with logging
- **Capture “before vs after”** package state
- **Store logs** in a predictable location
- **Make troubleshooting easy** with clear commands and log checks

This repo includes:
- a patch script (`patch.sh`)
- a systemd service + timer (runs on schedule)
- logs + reporting output

---

## Architecture Diagram

### systemd timer automation

![Architecture Diagram](screenshots/architecture.png)

---

## Step-by-step CLI

> **Tested on Ubuntu 20.04/22.04** (works on most Debian/Ubuntu systems)

### 1) Create project structure

```bash
mkdir -p patch-management-automation/{scripts,systemd,docs,logs}
cd patch-management-automation
```

### 2) Create the patch script

```bash
cat > scripts/patch.sh <<'EOF'
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
EOF

chmod +x scripts/patch.sh
```

### 3) Create systemd service

```bash
cat > systemd/patching.service <<'EOF'
[Unit]
Description=Weekly Patch Management Automation
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/patch.sh
EOF
```

### 4) Create systemd timer (weekly schedule)

This example runs **Sunday at 2:00 AM**.

```bash
cat > systemd/patching.timer <<'EOF'
[Unit]
Description=Run patching.service weekly

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

### 5) Install files + enable timer

```bash
# install script
sudo cp scripts/patch.sh /usr/local/bin/patch.sh
sudo chmod +x /usr/local/bin/patch.sh

# install systemd units
sudo cp systemd/patching.service /etc/systemd/system/patching.service
sudo cp systemd/patching.timer /etc/systemd/system/patching.timer

# reload + enable
sudo systemctl daemon-reload
sudo systemctl enable --now patching.timer
```

### 6) Verify the schedule

```bash
systemctl list-timers --all | grep patching || true
systemctl status patching.timer --no-pager
```
![alt text](image.png)
**Screenshot — Timer enabled + next run time**
![Timer Status](screenshots/01-timer-status.png)

### 7) Run once manually (for testing)

```bash
#sudo systemctl start patching.service
sudo systemctl start --no-block patching.service
sudo systemctl status patching.service --no-pager
```

**Screenshot — Manual patch run success**
![Service Success](screenshots/02-service-success.png)

### 8) Check logs and report

```bash
# systemd logs
journalctl -u patching.service -n 100 --no-pager

# patch logs
sudo ls -lah /var/log/patching
sudo tail -n 80 /var/log/patching/patch_*.log
sudo cat /var/log/patching/report_*.txt | tail -n 30
```
![alt text](image.png)
**Screenshot — Log folder output**
![Logs](screenshots/03-log-files.png)

**Screenshot — Sample patch log content**
![Patch Log](screenshots/04-patch-log.png)

---

## Outcome

After this setup:

* Patches run automatically on schedule (no manual effort)
* I always have **proof** of what happened (logs + reports)
* I can quickly see whether a **reboot is required**
* Troubleshooting is easy because everything is consistent and repeatable

---

## Troubleshooting

### 1) Timer not running

**Check:**

```bash
systemctl status patching.timer --no-pager
systemctl list-timers --all | grep patching || true
```

**Fix:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now patching.timer
```

---

### 2) Service failed

**Check logs:**

```bash
sudo systemctl status patching.service --no-pager
journalctl -u patching.service -n 200 --no-pager
```

**Common causes:**

* DNS/network not ready (rare, but possible)
* apt is locked (another process is using it)
* disk space is full

---

### 3) “Could not get lock /var/lib/dpkg/lock…”

**Check who is holding the lock:**

```bash
ps aux | egrep "apt|dpkg|unattended" | grep -v egrep
```

**Fix (safe approach):**

* Wait if `unattended-upgrades` is running
* Then retry:

```bash
sudo systemctl start patching.service
```

---

### 4) Disk space issues

**Check:**

```bash
df -h
sudo du -sh /var/log/* | sort -h | tail -n 20
```

**Fix:**

```bash
sudo apt-get autoremove -y
sudo apt-get clean
```

---

### 5) Reboot required after patches

**Check:**

```bash
test -f /var/run/reboot-required && echo "Reboot required"
cat /var/run/reboot-required.pkgs || true
```

---

## GitHub Repo Link

`https://github.com/lily4499/linux-projects/patch-management-automation`


