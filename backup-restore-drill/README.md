
# Backup & Restore Drill (Linux) — “I can recover fast when things go wrong”

## Context

In a real Linux environment, backup is not enough by itself. What matters is whether I can **restore quickly and correctly** when something breaks.

For this project, I practiced a real backup and restore drill on Linux. I backed up important application data, configuration files, and a small database, then I **simulated a failure** and restored everything to prove recovery works.

This project shows that I do not just create backups and leave them there. I also test recovery, validate the restored data, and check that the service can come back in a safe and usable state.

---

## Problem

In real environments, failures happen all the time:

* Someone deletes an important folder by mistake
* A bad deployment overwrites config files
* A disk issue corrupts application data
* A database becomes unreadable or gets wiped
* A server problem forces recovery from backup

The real problem is not only data loss. The real problem is **slow recovery** and **unclear restore steps**.

If backups exist but nobody has tested restore, then backups are only theory. During an incident, that becomes risky for the business.

---

## Solution

I built a simple backup and restore drill on Linux to practice the full recovery process.

The project includes:

* Backup of application data
* Backup of configuration files
* Backup of database content
* Integrity verification with checksums
* Restore testing after simulated failure
* Log review for troubleshooting
* Validation after recovery

Instead of only proving that backup files exist, I proved that I can actually **recover the environment and verify it works again**.

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

---

## Workflow

### Goal 1 — Prepare data that must be protected

I created a simple app structure with:

* application data
* configuration files
* a small database for backup testing

The goal here was to have something realistic to protect, just like a real Linux server hosting an application.

---

### Goal 2 — Run the backup and confirm it completed successfully

I performed the backup and confirmed that the backup location contained the expected files for:

* app data
* config data
* database export
* checksum file
* backup log

This step proves the backup process ran successfully and produced usable artifacts.

**Screenshot — Backup folder created**
![Backup folder created](screenshots/01-backup-folder.png)

**What it should show:**

* backup date folder created
* backup files present
* expected backup structure exists

---

### Goal 3 — Review backup logs and confirm there were no obvious errors

After the backup completed, I checked the backup log to make sure the process ran cleanly and recorded the expected actions.

This step matters because backup logs are often the first place to investigate when a scheduled backup fails or produces incomplete results.

**Screenshot — Backup log success**
![Backup log](screenshots/02-backup-log.png)

**What it should show:**

* backup started successfully
* backup completed successfully
* no major errors in the log

---

### Goal 4 — Simulate a failure on purpose

To make the project realistic, I deleted important files and removed application content so I could test real recovery.

This is the most important part of the drill: proving I can recover after damage, not just produce backup files.

**Screenshot — Simulated failure**
![Failure simulation](screenshots/03-failure-simulation.png)

**What it should show:**

* missing app files
* missing or damaged config
* database/content no longer available
* failure state clearly visible

---

### Goal 5 — Restore from backup and validate recovery

I restored the application data, configuration files, and database from the backup, then validated that the environment was usable again.

Validation included checking that:

* config files were back
* application files were restored
* database content was available again
* the restore process completed without integrity errors

**Screenshot — Restore validation**
![Restore validation](screenshots/04-restore-validation.png)

**What it should show:**

* restore completed successfully
* restored files visible again
* restored config available
* restored database/content accessible

---

## Business Impact

This project reflects real operational value.

A tested backup and restore process helps the business by:

* reducing downtime during incidents
* improving recovery confidence
* protecting important data and configuration
* making incident response faster
* lowering the risk of failed recovery during production problems

In simple terms, this means I can help a team recover faster when things go wrong instead of wasting time guessing during an outage.

It also shows good operational discipline: **backup is only useful when restore has been tested**.

---

## Troubleshooting

### Backup completed but expected files are missing

Possible causes:

* wrong source path
* backup script skipped part of the data
* permission issue on source files

What to check:

* backup destination contents
* backup log output
* source folders before and after backup

---

### Restore fails because checksum verification does not pass

Possible causes:

* backup files were modified
* backup is incomplete
* archive corruption happened

What to do:

* use a different backup date
* re-run a clean backup
* verify checksum file against backup artifacts

---

### Database restore does not work

Possible causes:

* database engine/tool is not installed
* export file is incomplete
* restore command used wrong database path

What to check:

* database client availability
* backup file existence
* restore output and error messages

---

### Scheduled backup did not run

Possible causes:

* cron entry missing
* wrong path in scheduled command
* script permission problem
* environment variables not available in cron context

What to check:

* cron listing
* system logs
* backup log timestamp
* script executable permission

---

### Restore completed but application is still unhealthy

Possible causes:

* config file is restored but incorrect
* service restart needed
* app depends on something not recovered yet
* database restored but app cannot connect

What to check:

* service status
* application logs
* config file contents
* health endpoint or app response

---

## Useful CLI

These are useful commands for validation and troubleshooting during backup and restore work.

### Check backup folder contents

```bash
ls -lah /backups/myapp/$(date +%F)
```

### Check backup log

```bash
sudo tail -n 50 /var/log/myapp/backup.log
```

### Show all available backup dates

```bash
ls -1 /backups/myapp
```

### Check whether important app files exist

```bash
sudo ls -lah /opt/myapp/data
sudo ls -lah /etc/myapp
```

### Validate restored database content

```bash
sudo sqlite3 /opt/myapp/data/app.db "SELECT * FROM users;"
```

### Re-run backup manually

```bash
sudo /usr/local/bin/backup-myapp.sh
```

### Re-run restore manually

```bash
sudo /usr/local/bin/restore-myapp.sh "$(date +%F)"
```

### Check checksum file during restore troubleshooting

```bash
cd /backups/myapp/$(date +%F) && sha256sum -c checksums.txt
```

### Check cron entry

```bash
sudo crontab -l
```

### Check cron-related logs

```bash
sudo grep CRON /var/log/syslog | tail -n 50
```

### Check service health after restore

```bash
systemctl status myapp
curl -I http://localhost:8080/health
```

---

## Cleanup

If I want to remove the lab after testing, I clean up the app data, config, backup files, and logs created for the drill.

Example cleanup areas:

* `/opt/myapp`
* `/etc/myapp`
* `/backups/myapp`
* `/var/log/myapp`
* scheduled cron entry if added for the lab

This keeps the environment clean after the drill is complete.

---

