
# Auto-Heal Service Reliability (systemd + Health Check Script)

## Context

In real operations, a service can stop working at any time. Sometimes the process crashes. Sometimes the service still looks running, but the port is not listening anymore or the application is not answering correctly.

For this project, I built a simple **auto-heal reliability setup on Linux** using **systemd** and a **health-check script**. The goal was to create a small but practical recovery workflow that can automatically detect a failure, restart the service, and keep proof in logs.

This follows a real operations idea:

**detect → recover → log evidence**

---

## Problem

When a service fails, users can experience downtime before anyone notices. That means:

* users cannot access the application
* alerts or tickets start coming in
* someone has to log in and restart the service manually
* recovery takes longer than it should

The problem is even worse when the service appears to be running but is not actually healthy from the user side.

---

## Solution

I implemented a lightweight auto-heal pattern using **systemd + Bash**.

The setup works like this:

* a **health-check script** checks whether the service is healthy
* the script verifies:

  * the service is active in systemd
  * the application port is listening
  * the HTTP endpoint responds correctly
* if the service is unhealthy, the script:

  * restarts the service automatically
  * writes the result into a log file
* a **systemd oneshot service** runs the script
* a **systemd timer** triggers that check every 60 seconds

This creates a simple recovery loop that helps reduce downtime automatically.

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

---

## Workflow

### 1. Demo service is running

**Goal:** Have a simple target service to monitor and recover.

I used a demo web service running on port **8080**. This service acts like the application I want to protect with auto-heal logic.

---

### 2. Health-check script validates service health

**Goal:** Detect whether the service is truly healthy.

The health-check script verifies three things:

* the service is active in systemd
* the port is listening
* the HTTP endpoint returns a good response

If all checks pass, the script records a healthy log entry.

#### Screenshot

* `screenshots/02-auto-heal-log.png`

![02 - Auto-heal log proof](screenshots/02-auto-heal-log.png)

**What it should show:** proof that the script writes health and recovery events into the auto-heal log.

---

### 3. systemd service runs the health-check logic

**Goal:** Run the health-check script through systemd.

I wrapped the script inside a oneshot systemd service so the check can be executed in a controlled and standard Linux service workflow.

This makes it easier to troubleshoot later using service status and journal logs.

---

### 4. systemd timer schedules the checks every 60 seconds

**Goal:** Run health checks automatically without manual action.

I used a systemd timer to trigger the health-check service every 60 seconds. This means the server keeps checking service health continuously.

#### Screenshot

* `screenshots/01-timer-running.png`

![01 - Timer running](screenshots/01-timer-running.png)

**What it should show:** the auto-heal timer is enabled and scheduled to run repeatedly.

---

### 5. Failure is simulated

**Goal:** Prove the setup can recover automatically.

To test the reliability workflow, I intentionally stopped the demo service. The timer later triggered the health-check, the script detected the failure, restarted the service, and logged the recovery event.

This proves the auto-heal pattern is working.

---

### 6. Service is healthy again after restart

**Goal:** Confirm that recovery was successful.

After the automatic restart, the service became healthy again and the log showed the restart and recovery result.

#### Screenshot

* `screenshots/03-service-healthy.png`

![03 - Service healthy after recovery](screenshots/03-service-healthy.png)

**What it should show:** proof that the service is healthy again after the auto-heal process restarted it.

---

## Business Impact

This project shows a practical reliability pattern that is useful in real environments.

Business value includes:

* **reduced downtime** because the server can recover the service automatically
* **faster response** without waiting for a person to restart the service
* **better operational visibility** through recovery logs
* **repeatable reliability pattern** that can be reused for other Linux services
* **stronger operations maturity** by combining monitoring, recovery, and evidence

Even though this is a small project, it demonstrates the kind of thinking used in production support and site reliability work.

---

## Troubleshooting

### Timer is enabled but not triggering

If the timer is not running as expected, check whether it is enabled, scheduled, and loaded correctly.

### Script works manually but fails through systemd

If the script works from the shell but not from the service, the problem is usually related to permissions, execution path, or service environment.

### Service restarts but still stays unhealthy

If auto-heal restarts the service but the application is still down, the root cause may be deeper than a process failure, such as port binding problems or application errors.

### Health check always shows unhealthy

If the script always reports unhealthy, verify that the service name, port, and URL being checked match the actual application settings.

---

## Useful CLI

### General verification

```bash
systemctl is-active demo-web.service
systemctl status demo-web.service --no-pager
systemctl status auto-heal.service --no-pager
systemctl status auto-heal.timer --no-pager
systemctl list-timers --all | grep auto-heal || true
```

### Check logs

```bash
tail -n 30 /var/log/auto-heal/auto-heal.log
journalctl -u auto-heal.service --since "30 minutes ago" --no-pager
journalctl -u demo-web.service --since "30 minutes ago" --no-pager
```

### Test the application

```bash
curl -I http://localhost:8080
curl -v http://localhost:8080
ss -lntp | grep 8080 || true
```

### Manual service actions

```bash
sudo systemctl start demo-web.service
sudo systemctl stop demo-web.service
sudo systemctl restart demo-web.service
sudo systemctl restart auto-heal.timer
sudo systemctl daemon-reload
```

### Troubleshooting checks

```bash
ls -l /usr/local/bin/health-check.sh
systemctl list-units --type=service | grep demo-web || true
```

---

## Cleanup

```bash
sudo systemctl disable --now auto-heal.timer || true
sudo systemctl disable --now demo-web.service || true

sudo rm -f /etc/systemd/system/auto-heal.timer
sudo rm -f /etc/systemd/system/auto-heal.service
sudo rm -f /etc/systemd/system/demo-web.service
sudo systemctl daemon-reload

sudo rm -f /usr/local/bin/health-check.sh
sudo rm -rf /opt/demo-web
sudo rm -rf /var/log/auto-heal
```

---
