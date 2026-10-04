# Operations Runbook

## Scope

This runbook covers auditing, validating, deploying and rolling back the infrastructure configuration provided by this repository.

Treat every target as production unless its environment classification is confirmed.

## Mandatory Prerequisites

Before any configuration change:

- Confirm the target environment
- Obtain approved change authorization
- Confirm application-owner participation
- Verify current backups
- Confirm independent console or recovery access
- Verify SSH key access
- Review the exact host limit
- Confirm package sources are approved
- Confirm HAProxy, HTTPD, NFS, firewalld and monitoring requirements
- Verify that private inventory and variables are excluded from Git
- Define measurable acceptance criteria
- Document the rollback decision point

## 1. Install Local Validation Dependencies

Use an isolated Python environment where practical:

```bash
python -m pip install --requirement requirements-dev.txt
ansible-galaxy collection install --requirements-file requirements.yml
```

These commands prepare the control environment only.

## 2. Run Static Validation

```bash
bash scripts/validate.sh
```

Expected result:

```text
All static validation checks passed.
```

Static validation does not prove live-system compatibility.

## 3. Create Private Inventory

Create an ignored inventory beneath:

```text
inventory/private/hosts.ini
```

Never commit:

- Real hostnames
- IP addresses
- Usernames
- Credentials
- Private keys
- Internal domains
- Infrastructure diagrams containing identifying data

Verify exclusion:

```bash
git check-ignore -v inventory/private/hosts.ini
```

## 4. Run Read-Only Audit

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/audit.yml \
  --limit approved_test_host
```

Review:

- Package presence
- Service status
- HAProxy configuration validation
- HTTPD configuration validation
- HTTP health response
- NFS mount presence
- MariaDB TCP reachability
- Prometheus prerequisites

Audit findings are not authorization to remediate.

## 5. Prepare Private Change Variables

Create an ignored file such as:

```text
inventory/private/change.yml
```

Example structure:

```yaml
---
restaurant_ha_change_approved: true
restaurant_ha_recovery_access_confirmed: true
restaurant_ha_backup_confirmed: true

restaurant_ha_manage_haproxy: false
restaurant_ha_manage_httpd: true
restaurant_ha_manage_nfs_client: false
restaurant_ha_manage_firewalld: false
restaurant_ha_manage_monitoring: false
restaurant_ha_validate_mariadb: true
```

Enable only the approved control families. Replace documentation-only values through the private variables file.

## 6. Preview the Change

Run check mode where supported:

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/deploy.yml \
  --limit approved_test_host \
  --extra-vars "@inventory/private/change.yml" \
  --check \
  --diff
```

Limitations:

- Package, service, mount and network behavior may not be fully predictable in check mode.
- A successful preview does not replace testing.
- Diff output may contain sensitive configuration and must be sanitized before sharing.

## 7. Deploy to One Non-Production Host

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/deploy.yml \
  --limit approved_test_host \
  --extra-vars "@inventory/private/change.yml"
```

The deployment playbook:

- Requires an explicit restricted host limit
- Processes one host at a time
- Stops on the first failure
- Creates protected backups
- Validates configurations before reload where supported
- Runs post-change checks

## 8. Validate Service Health

Validate from both the target host and an approved client path.

Check:

- HAProxy service and backend health
- HTTPD service status
- `/healthz` response
- Application response
- NFS mount and approved read/write behavior
- MariaDB connectivity
- Prometheus target state
- Logs for new errors
- Load-balancer node distribution
- User acceptance criteria

Do not declare success from service status alone.

## 9. Expand Carefully

After the pilot succeeds:

1. Obtain approval to continue.
2. Keep `serial: 1`.
3. Add one host at a time.
4. Confirm the load balancer removes the node before maintenance where required.
5. Validate the node before returning it to service.
6. Monitor application and infrastructure health between nodes.

## 10. Controlled Rollback

Identify the exact protected backup file first.

Create an ignored rollback variables file:

```yaml
---
restaurant_ha_change_approved: true
restaurant_ha_recovery_access_confirmed: true
restaurant_ha_backup_confirmed: true
restaurant_ha_rollback_approved: true
restaurant_ha_rollback_component: httpd
restaurant_ha_rollback_source: /var/backups/restaurant-ha/httpd/exact-backup-file
```

Run:

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/rollback.yml \
  --limit approved_single_host \
  --extra-vars "@inventory/private/rollback.yml"
```

Supported automated configuration rollback components:

- HAProxy
- Apache HTTPD
- Prometheus file-discovery targets

NFS and firewall rollback require environment-specific state review and are intentionally not automated.

## 11. Post-Rollback Validation

Verify:

- Restored configuration syntax
- Service reload result
- Health endpoint
- Load-balancer behavior
- Application availability
- Logs
- Monitoring state
- Original incident or change symptom

Document the outcome and preserve sanitized evidence.

## Emergency Stop Conditions

Stop immediately if:

- Recovery access is unavailable
- The target environment is uncertain
- The inventory limit is broader than approved
- A backup cannot be verified
- Configuration validation fails
- A node does not leave or rejoin load-balancer rotation correctly
- Application behavior changes unexpectedly
- Database or shared-storage consistency is uncertain
