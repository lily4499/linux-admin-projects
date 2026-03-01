
# User & Permission Management  
## Kubernetes RBAC + Namespace Isolation  
### Least Privilege Access Control for Multi-Environment Operations

## Context

In a real Kubernetes environment, access control is not optional. As clusters grow, different teams need different levels of access, and production must be protected from unnecessary risk.

This project demonstrates how I implemented **Kubernetes RBAC with namespace isolation** to enforce **least privilege**, reduce blast radius, and create a permission model that is easier to audit, troubleshoot, and control during real operational incidents.

This is the kind of setup that matters in production because it helps answer critical questions fast:

- Who can deploy?
- Who can only view?
- Who can access production?
- How do I verify permissions quickly?
- How do I revoke access during an incident?

---

## Problem

In many environments, Kubernetes access is too broad and poorly controlled. That creates operational risk very quickly.

Common failure points include:

- Multiple people sharing the same high-privilege kubeconfig
- Developers receiving more permissions than their role requires
- No clear separation between `dev`, `staging`, and `prod`
- No fast way to verify who has access to what
- Slow response during incidents because access is not clearly scoped
- Increased chance of accidental changes in production

The result is simple: **weak access control increases the chance of downtime, misconfiguration, and security exposure**.

---

## Solution

To solve this, I implemented a **role-based access control model** using **Kubernetes RBAC** and **namespace isolation**.

The solution includes:

- Separate namespaces for `dev`, `staging`, and `prod`
- Dedicated identities using ServiceAccounts
- Namespace-specific Roles for developer and viewer access
- RoleBindings to attach permissions only where needed
- Stricter access in production
- Permission validation using `kubectl auth can-i`
- Fast revocation path for incident response

This approach creates a more secure and operationally realistic Kubernetes environment where access is **intentional, limited, and verifiable**.

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

**Architecture summary:**

- **Platform administrators** hold elevated control at the cluster level
- **Developers** receive scoped permissions only inside approved namespaces
- **Viewers** get read-only access for visibility without change authority
- **Production access is more restricted** than lower environments
- **RBAC + namespace isolation** work together to reduce risk and support least privilege

This reflects a real operations model where teams can work efficiently without exposing the cluster to unnecessary permission sprawl.

---

## Workflow

### Goal 1 — Isolate environments so access can be controlled safely

I created separate namespaces for `dev`, `staging`, and `prod` so permissions can be assigned by environment instead of giving broad access across the cluster.

This is a foundational control because namespace boundaries make it easier to limit what each identity can see or modify.

**Screenshot — Namespaces created**  
![Namespaces created](screenshots/01-namespaces.png)

What this proves:

- Environments are separated
- Access can be managed per namespace
- The cluster is ready for scoped RBAC enforcement

---

### Goal 2 — Define controlled identities for real operational access

I created ServiceAccounts to represent operational identities for developers and viewers instead of relying on broad shared admin access.

This mirrors real production thinking: access should be assigned to a defined identity with a specific purpose.

---

### Goal 3 — Give developers the ability to work only where they should

I created a developer role in the `dev` namespace so a dev identity can manage application-related resources there without receiving cluster-wide privileges.

That means the developer can work in the correct environment while staying isolated from production.

**Screenshot — DEV roles created**  
![RBAC Roles](screenshots/02-dev-roles.png)

What this proves:

- Permissions are being defined intentionally
- Access is scoped to namespace level
- Developer permissions are controlled instead of over-granted

---

### Goal 4 — Bind developer permissions to the correct identity

I linked the developer role to the intended ServiceAccount so the permissions are actually enforceable for that identity in the `dev` namespace.

This is what turns RBAC design into active access control.

**Screenshot — DEV role bindings created**  
![RBAC Bindings](screenshots/03-dev-bindings.png)

What this proves:

- The correct identity is attached to the correct permission set
- RBAC is not only defined, but actively assigned
- Access can be managed cleanly and revoked when needed

---

### Goal 5 — Provide safe read-only visibility for non-admin users

I created viewer-level access for users who need operational visibility but should not be allowed to create, change, or delete resources.

This is important in real environments because many users need to inspect workloads and logs without having change authority.

---

### Goal 6 — Enforce stricter access in production

I created production viewer access as read-only, reflecting a more controlled model for sensitive workloads.

This matches a real-world expectation: production should not be open for routine modification by default.

**Screenshot — PROD RBAC created**  
![PROD RBAC](screenshots/04-prod-rbac.png)

What this proves:

- Production access is deliberately stricter
- Permissions differ by environment
- The access model supports operational safety

---

### Goal 7 — Validate permissions before calling the setup complete

I verified effective permissions using authorization checks to confirm that each identity can do only what it is supposed to do.

This is a critical operational step because RBAC is not complete until access is tested.

**Screenshot — Permission verification**  
![Can-I Checks](screenshots/05-can-i-checks.png)

What this proves:

- Developer access works in `dev`
- Viewer access remains read-only
- Production permissions are limited appropriately
- Least privilege is enforced and testable

---

## Business Impact

This project improves both **security posture** and **operational discipline**.

### Why this matters in a real company

- **Reduces production risk** by preventing unnecessary write access
- **Limits blast radius** when a user or workload is compromised
- **Improves auditability** by making permissions easier to review and explain
- **Supports separation of duties** across teams and environments
- **Accelerates incident response** because access can be verified or revoked quickly
- **Builds a production-ready access model** instead of relying on shared admin behavior

### Operational value delivered

- Developers can work faster in the correct environment without exposing production
- Viewers can inspect workloads and logs safely
- Platform teams retain stronger control over critical environments
- Permission checks become repeatable and easy to prove
- The cluster becomes easier to govern at scale

This is the kind of access design that helps teams move faster **without sacrificing control**.

---

## Troubleshooting

### Forbidden error when a user tries an action

This usually means the identity does not have the required Role or RoleBinding in that namespace.

Things to check:

- Is the Role present in the correct namespace?
- Is the RoleBinding attached to the right ServiceAccount?
- Is the user testing in the correct namespace?
- Is the requested action actually allowed by the role?

---

### Role exists but access still does not work

This often happens when the binding references:

- the wrong role name
- the wrong subject name
- the wrong namespace
- a ServiceAccount that does not match the intended identity

The permission model can look correct at first glance, but one wrong reference breaks the entire access path.

---

### Access works in dev but fails in prod

That may be expected by design.

In this setup, production is intentionally more restrictive. If a user can deploy in `dev` but cannot do the same in `prod`, that confirms environment-level protection is working.

---

### Need to revoke access during an incident

The fastest response is usually to remove or update the RoleBinding.

This is one of the biggest strengths of RBAC: access can be cut quickly without rebuilding the cluster or changing everything globally.

---

## Useful CLI

### General verification

```bash
kubectl get ns
kubectl get sa -n dev
kubectl get sa -n prod
kubectl get role -n dev
kubectl get rolebinding -n dev
kubectl get role -n prod
kubectl get rolebinding -n prod
````

### Permission validation

```bash
kubectl auth can-i create deployments -n dev --as=system:serviceaccount:dev:dev-user
kubectl auth can-i delete pods -n dev --as=system:serviceaccount:dev:dev-user
kubectl auth can-i get pods -n dev --as=system:serviceaccount:dev:dev-viewer
kubectl auth can-i delete pods -n dev --as=system:serviceaccount:dev:dev-viewer
kubectl auth can-i get deployments -n prod --as=system:serviceaccount:prod:prod-viewer
kubectl auth can-i create deployments -n prod --as=system:serviceaccount:prod:prod-viewer
```

### Troubleshooting CLI

```bash
kubectl -n dev describe rolebinding dev-developer-binding
kubectl -n dev describe rolebinding dev-viewer-binding
kubectl -n dev describe role dev-developer
kubectl -n dev describe role dev-viewer
kubectl -n prod describe rolebinding prod-viewer-binding
kubectl -n prod describe role prod-viewer
kubectl auth can-i --list --as=system:serviceaccount:dev:dev-user -n dev
kubectl auth can-i --list --as=system:serviceaccount:dev:dev-viewer -n dev
kubectl auth can-i --list --as=system:serviceaccount:prod:prod-viewer -n prod
```

### Fast access revocation

```bash
kubectl -n dev delete rolebinding dev-developer-binding
kubectl -n dev delete rolebinding dev-viewer-binding
kubectl -n prod delete rolebinding prod-viewer-binding
```

---

## Cleanup

```bash
kubectl delete rolebinding dev-developer-binding -n dev
kubectl delete rolebinding dev-viewer-binding -n dev
kubectl delete rolebinding prod-viewer-binding -n prod

kubectl delete role dev-developer -n dev
kubectl delete role dev-viewer -n dev
kubectl delete role prod-viewer -n prod

kubectl delete serviceaccount dev-user -n dev
kubectl delete serviceaccount dev-viewer -n dev
kubectl delete serviceaccount prod-viewer -n prod

kubectl delete namespace dev
kubectl delete namespace staging
kubectl delete namespace prod
```

