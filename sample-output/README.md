# Restaurant High-Availability Infrastructure

[![HA Infrastructure Validation](https://github.com/solonsah/restaurant-ha-infrastructure/actions/workflows/ha-validation.yml/badge.svg)](https://github.com/solonsah/restaurant-ha-infrastructure/actions/workflows/ha-validation.yml)

A production-oriented Linux infrastructure framework for Apache HTTPD web services, HAProxy load balancing, shared NFS storage, MariaDB connectivity, Prometheus monitoring and controlled recovery.

## Project Purpose

This project demonstrates how to design and automate a multi-tier restaurant-platform infrastructure while preserving operational safety.

It focuses on:

- Read-only discovery before remediation
- Explicit approval gates
- Redundant load-balancing and web tiers
- Apache HTTPD across four web nodes
- Shared NFS client configuration
- MariaDB network validation
- Firewalld integration
- Prometheus target discovery
- Configuration backups
- Post-change validation
- Controlled rollback
- Sanitized public documentation

This repository does not contain a restaurant application, PHP code, Nginx configuration, database credentials or production data.

## Architecture

| Tier | Example design | Function |
|---|---|---|
| Access | Approved private DNS name or virtual IP | Client entry point |
| Load balancing | Two HAProxy nodes | Health checks and request distribution |
| Web | Four Apache HTTPD nodes | Horizontally scaled web service |
| Shared storage | Approved NFS endpoint | Shared application content |
| Database | Approved MariaDB endpoint | Application data service |
| Monitoring | Prometheus and Node Exporter | Metrics and availability visibility |

HAProxy uses least-connections balancing and checks each web node through `/healthz`.

See [Architecture](docs/architecture.md) for availability boundaries and remaining single points of failure.

## Safety Design

Every configuration family is disabled by default:

```yaml
restaurant_ha_manage_haproxy: false
restaurant_ha_manage_httpd: false
restaurant_ha_manage_nfs_client: false
restaurant_ha_manage_firewalld: false
restaurant_ha_manage_monitoring: false
```

Configuration changes require explicit confirmation that:

- The change is approved
- Current backups are confirmed
- Independent recovery access is available
- The target runs a documented RHEL version
- Ansible has effective root privileges
- The run uses a restricted host limit
- Only the required management families are enabled

Deployment uses `serial: 1` and stops on the first failure.

## Supported Design Targets

| Platform | Status |
|---|---|
| RHEL 8 | Designed target; live compatibility testing required |
| RHEL 9 | Designed target; live compatibility testing required |
| RHEL 10 | Planned compatibility testing |
| Ubuntu 24.04 | CI validation runner only |

Passing CI does not prove that the role has been exercised on live RHEL hosts.

## Repository Structure

```text
.
├── .github/workflows/
│   └── ha-validation.yml
├── ansible/
│   ├── playbooks/
│   │   ├── audit.yml
│   │   ├── deploy.yml
│   │   └── rollback.yml
│   └── roles/restaurant_ha/
│       ├── defaults/
│       ├── handlers/
│       ├── tasks/
│       └── templates/
├── docs/
│   ├── architecture.md
│   ├── operations-runbook.md
│   └── security-controls.md
├── inventory/
│   └── example.ini
├── sample-output/
│   └── README.md
├── scripts/
│   └── validate.sh
├── .ansible-lint
├── .gitattributes
├── .gitignore
├── .yamllint
├── ansible.cfg
├── requirements-dev.txt
└── requirements.yml
```

## Read-Only Audit

Create an ignored private inventory, then run:

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/audit.yml \
  --limit approved_test_host
```

The audit checks:

- Installed packages
- Service state
- Existing HAProxy configuration
- Existing HTTPD configuration
- HTTP health response
- NFS mount presence
- MariaDB TCP reachability
- Prometheus prerequisites

Audit mode does not authorize remediation.

## Controlled Deployment

Use an approved private variables file and one restricted non-production host:

```bash
ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/deploy.yml \
  --limit approved_test_host \
  --extra-vars "@inventory/private/change.yml"
```

The role can manage:

- HAProxy package, configuration and service
- Apache HTTPD package, virtual host and health endpoint
- Persistent NFS client mount
- Approved firewalld HTTP access
- Prometheus file-discovery targets

Each family must be enabled separately.

## Backup and Rollback

Managed configuration backups are stored under:

```text
/var/backups/restaurant-ha/
```

Supported automated configuration rollback components:

- HAProxy
- Apache HTTPD
- Prometheus target discovery

Rollback requires:

- Exact backup-file selection
- Explicit rollback approval
- Change approval
- Backup confirmation
- Recovery-access confirmation
- A restricted single-host limit

NFS and firewall rollback remain manual because they require environment-specific state review.

## Local Validation

Install pinned dependencies:

```bash
python -m pip install --requirement requirements-dev.txt
ansible-galaxy collection install --requirements-file requirements.yml
```

Run all static checks:

```bash
bash scripts/validate.sh
```

Validation includes:

- YAML formatting
- ShellCheck
- Ansible collection presence
- Ansible linting
- Audit playbook syntax
- Deployment playbook syntax
- Rollback playbook syntax

## CI Validation

GitHub Actions runs on a fixed Ubuntu 24.04 runner with read-only repository permissions.

The workflow does not:

- Connect to managed hosts
- Use infrastructure credentials
- Run deployment
- Create cloud resources
- Apply firewall rules
- Mount storage
- Restart production services

## Security

The repository excludes private inventories, credentials, keys, certificates, database exports, backups, reports, logs and runtime data.

Review [Security Controls](docs/security-controls.md) before adapting the framework.

## Important Limitations

- Multiple web nodes do not make the entire platform highly available.
- The example NFS and MariaDB endpoints are single service endpoints.
- Virtual-IP or DNS failover for HAProxy is not automated.
- TLS termination and certificate management are not implemented.
- Application deployment and session-state design are outside scope.
- Database replication, backup and failover are outside scope.
- Live RHEL, SELinux, firewalld and application testing remains required.
- This framework does not certify security compliance or production readiness.

## Operations

See the [Operations Runbook](docs/operations-runbook.md) for audit, deployment, validation, expansion, rollback and emergency-stop procedures.

## License

This project is licensed under the [MIT License](LICENSE).
