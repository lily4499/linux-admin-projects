
# Linux Projects (Real “Ops” Automation & Hardening)

This folder is my **Linux operations portfolio**.  
Each subfolder is a hands-on project where I practice real sysadmin/DevOps work the way an ops team does it:

**secure → automate → monitor → recover (with proof)**

Every project folder has its own `README.md` with clear steps, commands, and evidence (screenshots/logs).

---

## What you’ll find here

### Current projects in this folder
- `auto-heal-service-reliability/`  
  **systemd + health-check automation** to detect failure and restart a service automatically (reliability pattern).

- `backup-restore-drill/`  
  A practical **backup + restore** drill to prove recovery works (not just “we have backups”).

- `disk-mem-alert/`  
  A lightweight **disk + memory monitoring** script + systemd timer/service with alerts and logs.

- `patch-management-automation/`  
  Automated **weekly patching** using Bash + systemd timer/service with logging and verification.

- `secure-ssh-hardening-no-password-login/`  
  SSH security hardening: **keys only**, disable root login, firewall rules, and brute-force protection (Fail2ban).

- `user-permission-management-rbac/`  
  User and permission controls using **least privilege** and access verification (ops-style access management).

> These projects focus on real ops priorities: **security, reliability, automation, and recoverability**.

---

## How I build Linux projects (my standard)

1. **Goal**
   - what problem I’m solving and why it matters in production

2. **Implementation**
   - scripts + configuration (systemd units, timers, permissions)

3. **Verification**
   - commands to prove it works (status, logs, health checks)

4. **Evidence**
   - screenshots + log outputs saved in each project folder

5. **Troubleshooting**
   - common failures + how I fix them

---

## Common commands I use in most projects

### systemd (service + timer)
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now <service>
sudo systemctl enable --now <timer>
sudo systemctl status <service> --no-pager
sudo systemctl list-timers --all
````

### Logs (proof)

```bash
sudo journalctl -u <service> --no-pager -n 200
sudo tail -n 50 /var/log/<logfile>.log
```

### Networking / ports

```bash
sudo ss -lntp
curl -I http://127.0.0.1:<port>
```

### Security checks

```bash
sudo sshd -t
sudo ufw status verbose
sudo fail2ban-client status
```

---

## Folder standards (how each project is organized)

```text
linux-projects/
└── project-name/
    ├── README.md
    ├── scripts/            # bash/python scripts (if needed)
    ├── systemd/            # .service and .timer files (if needed)
    ├── configs/            # config files (ssh, fail2ban, etc.)
    ├── logs/               # sample logs or output (optional)
    └── screenshots/        # proof images
```

---

## Outcome (what this repo proves)

* I can automate Linux ops tasks using **Bash + systemd**
* I can harden systems with **secure SSH + firewall + brute-force protection**
* I validate changes with **logs, status checks, and health tests**
* I build projects in a repeatable, production-style way with documentation and evidence

---


