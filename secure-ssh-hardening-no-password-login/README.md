
# Secure SSH Access Hardening (No Password Login)

## Context

In many Linux environments, SSH is the main way administrators connect to servers. If SSH is left with password login enabled, it becomes an easy target for attackers trying brute-force attempts, reused credentials, or weak passwords.

For this project, I hardened SSH access on a Linux server so that only trusted users with approved SSH keys can log in. I also added extra protections to reduce exposure and make unauthorized access much harder.

This is a practical Linux security hardening project focused on replacing password-based SSH access with key-based authentication, restricting access, and adding basic brute-force protection.

---

## Problem

Password-based SSH is simple to use, but it creates a serious security risk.

Common issues include:

- brute-force attacks against port 22
- reused or weak passwords
- accidental exposure of SSH to the internet
- attackers trying to log in as `root`
- too many users having unnecessary SSH access
- lack of visibility when failed login attempts happen

In a real environment, leaving SSH open with password login increases the chance of unauthorized access and weakens the security of the whole server.

---

## Solution

I secured SSH access by hardening the server in multiple layers.

The solution includes:

- enforcing **SSH key authentication only**
- disabling **password login**
- disabling **root login**
- limiting SSH access to only approved users
- reducing the attack surface
- enabling **Fail2ban** to block repeated failed login attempts
- using the firewall to allow only SSH access that is needed
- validating the configuration and checking logs after the change

This makes SSH access much more secure and closer to what is expected in a real production environment.

---

## Architecture

**Diagram — Key-only SSH + protection layers**  
![Architecture Diagram](screenshots/architecture.png)

This setup follows a simple security flow:

- the administrator connects from a trusted local machine
- the Linux server accepts only SSH key authentication
- password login is disabled
- root login is disabled
- firewall rules help limit exposure
- Fail2ban watches failed attempts and blocks abusive IPs
- logs can be reviewed for auditing and troubleshooting

---

## Workflow

### Goal 1 — Prepare the server for SSH hardening

First, I made sure the server had the required services and tools for secure SSH access and protection. This included the SSH service itself, firewall support, and Fail2ban for brute-force protection.

**Screenshot — Packages installed + SSH running**  
![Packages installed](screenshots/01-packages-installed.png)

---

### Goal 2 — Create and verify the approved admin user

Next, I created a dedicated admin user for SSH access instead of depending on root. This user is the approved account allowed to log in after hardening is applied.

**Screenshot — User created + groups verified**  
![User created](screenshots/02-user-created.png)

---

### Goal 3 — Generate a secure SSH key

I generated a secure SSH key pair from the local machine. This key is what replaces password-based access and becomes the trusted way to connect to the server.

**Screenshot — SSH key generated**  
![SSH keygen](screenshots/03-ssh-keygen.png)

---

### Goal 4 — Copy the public key to the server and test access

After generating the SSH key, I copied the public key to the server for the approved admin user. Then I tested logging in with the key to confirm access works before locking down password authentication.

**Screenshot — Public key copied to server**  
![Key copied](screenshots/04-key-copied.png)

**Screenshot — Successful key-based login**  
![Key login success](screenshots/05-key-login-success.png)

---

### Goal 5 — Harden the SSH configuration

Once key-based login was confirmed, I updated the SSH server configuration to disable password login, disable root login, and allow only the approved user to connect.

**Screenshot — Hardened sshd_config**  
![sshd config hardened](screenshots/06-sshd-config-hardened.png)

**Screenshot — SSH config validation passed**  
![sshd validation](screenshots/07-sshd-t-validation.png)

---

### Goal 6 — Restrict exposure with firewall rules

After hardening SSH itself, I verified that firewall rules were in place so only the intended SSH access is allowed.

**Screenshot — Firewall rules applied**  
![ufw status verbose](screenshots/08-ufw-status-verbose.png)

---

### Goal 7 — Add brute-force protection with Fail2ban

To reduce repeated login abuse, I enabled Fail2ban and confirmed the SSH jail was active. This adds automatic protection when too many failed attempts are detected.

**Screenshot — Fail2ban enabled**  
![fail2ban status](screenshots/09-fail2ban-status.png)

**Screenshot — SSHD jail active**  
![fail2ban sshd](screenshots/10-fail2ban-sshd-jail.png)

---

### Goal 8 — Verify that insecure access is blocked

After the hardening steps, I tested that password login no longer works, key login still works, and root login is denied.

**Screenshot — Password login denied**  
![Password denied](screenshots/11-password-login-denied.png)

**Screenshot — Key login still works**  
![Key login verified](screenshots/12-key-login-verified.png)

**Screenshot — Root login denied**  
![Root login denied](screenshots/13-root-login-denied.png)

---

### Goal 9 — Review logs and ban activity

Finally, I checked SSH logs and Fail2ban results to confirm login attempts are visible and protection is working as expected.

**Screenshot — SSH logs**  
![SSH logs](screenshots/14-ssh-logs.png)

**Screenshot — Fail2ban counters / bans**  
![Fail2ban bans](screenshots/15-fail2ban-bans.png)

---

### Goal 10 — Keep a recovery path if locked out

As part of safe hardening, I kept a rollback option available in case access was lost. This is important because SSH security changes can lock out the administrator if key setup is not tested first.

**Screenshot — Recovery / rollback example**  
![Rollback recovery](screenshots/16-rollback-recovery.png)

---

## Business Impact

This project improves security in a way that matters in real environments.

Main impact:

- reduces the risk of unauthorized SSH access
- removes password-based login, which is one of the most common attack paths
- prevents direct root login
- limits access to only approved users
- blocks repeated abusive login attempts automatically
- improves audit visibility through logs
- creates a safer baseline for Linux servers used in cloud or on-prem environments

In a business setting, this kind of hardening helps protect production servers, administrative access, and sensitive workloads from common attack methods.

---

## Troubleshooting

### Key login does not work

Possible causes:

- the public key was not added correctly
- the wrong user is being used
- the `.ssh` directory permissions are wrong
- the `authorized_keys` file permissions are wrong
- the SSH client is using the wrong private key

---

### Password login is still working

Possible causes:

- the SSH config change was not applied
- duplicate settings exist in the SSH config
- the SSH service was not restarted
- the wrong SSH config file was edited

---

### SSH service fails after config update

Possible causes:

- syntax error in `sshd_config`
- duplicate or conflicting settings
- unsupported option added by mistake

---

### Fail2ban is not banning failed attempts

Possible causes:

- the SSH jail is not enabled
- the wrong log path is being used
- Fail2ban service is not running
- failed attempts are not reaching the expected log source

---

### Firewall blocks valid SSH access

Possible causes:

- the SSH port rule is missing
- the wrong port was allowed in the firewall
- the firewall was enabled before confirming the SSH rule
- the SSH port was changed but the firewall was not updated

---

## Useful CLI

### General verification

```bash
systemctl status ssh --no-pager
systemctl status sshd --no-pager
id devopsadmin
groups devopsadmin
````

### SSH key verification

```bash
ls -la ~/.ssh/id_ed25519*
ssh devopsadmin@<SERVER_IP>
ssh -i ~/.ssh/id_ed25519 devopsadmin@<SERVER_IP>
```

### SSH config validation

```bash
sudo sshd -t
sudo sshd -t && echo "OK: sshd_config syntax is valid"
```

### Restart SSH service

```bash
sudo systemctl restart ssh
sudo systemctl restart sshd
```

### Firewall checks

```bash
sudo ufw status verbose
sudo ufw allow 22/tcp
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
```

### Fail2ban checks

```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

### SSH log checks

```bash
sudo tail -n 50 /var/log/auth.log
sudo journalctl -u ssh --no-pager -n 50
sudo journalctl -u sshd --no-pager -n 50
```

### Troubleshooting CLI

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
sudo grep -n '^\[sshd\]' /etc/fail2ban/jail.local
sudo nano +320 /etc/fail2ban/jail.local
sudo nano /etc/ssh/sshd_config
```

### Test blocked password login

```bash
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no devopsadmin@<SERVER_IP>
```

### Test root login blocked

```bash
ssh root@<SERVER_IP>
```

---

## Cleanup

This project is mainly a security hardening project, so cleanup usually means reversing the changes only if needed for testing or lab reset.

Possible cleanup actions:

* remove the test admin user if it was created only for the lab
* remove the SSH key from `authorized_keys` if rotating access
* disable or uninstall Fail2ban in a temporary lab
* reset firewall rules if this was only a practice environment
* restore the previous SSH configuration if rolling back in a test setup

If used in a real environment, these changes are usually meant to stay in place as part of the server security baseline.

```

