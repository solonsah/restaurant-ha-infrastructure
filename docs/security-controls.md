# Security Controls

## Security Model

This repository uses opt-in automation. Every configuration-management family is disabled by default, and change operations require explicit approval, backup confirmation and recovery-access confirmation.

## Repository Protection

The repository excludes:

- Credentials and secret files
- Private keys and certificates
- Private and environment-specific inventories
- Host and group variables
- Database exports
- Reports and backups
- Runtime monitoring data
- Logs and temporary files

Before every commit:

```bash
git status --short --untracked-files=all
git diff --cached --check
```

Review every staged file. Never assume `.gitignore` can remove a secret that was already committed.

## Host Access

Recommended controls:

- Use named administrative accounts
- Prefer SSH keys over passwords
- Use RSA keys where FIPS constraints require them
- Preserve host-key verification
- Use least privilege
- Require explicit privilege escalation
- Maintain independent console access during high-risk changes
- Restrict automation to approved inventory groups and host limits

## HAProxy

Implemented safeguards:

- Dedicated service account
- No embedded credentials
- No exposed statistics interface
- Backend health checks
- Candidate configuration validation
- Protected configuration backups
- Reload instead of unnecessary restart

Production additions requiring separate review:

- TLS termination
- Certificate lifecycle management
- Approved cipher policy
- Administrative-interface restrictions
- Log forwarding and retention
- Rate limiting or web application firewall integration

## Apache HTTPD

Implemented safeguards:

- Directory listing disabled
- Configuration validation before reload
- Basic response-security headers
- Dedicated virtual-host configuration
- Protected backups
- No PHP or unreviewed runtime assumptions

Production additions requiring separate review:

- TLS configuration and certificates
- Authentication and authorization
- Application-specific modules
- Content ownership
- SELinux file contexts
- Request-size and timeout limits
- Logging and retention requirements

## NFS

Implemented client safeguards:

- `nosuid`
- `nodev`
- `_netdev`
- Dedicated mount path
- Explicit opt-in management

Production review must address:

- NFS server access controls
- Network segmentation
- Export restrictions
- Root squashing
- Encryption requirements
- File ownership and permissions
- Availability and recovery
- Data-consistency expectations

## MariaDB

This repository performs TCP reachability checks only. It does not:

- Store database credentials
- Create users or schemas
- Import production data
- Change database configuration
- Claim database high availability

Credentials should come from an approved secrets-management process and must never be committed.

## Firewalld

The role:

- Requires firewalld to already be installed and running
- Does not change the default zone
- Opens only the explicitly managed HTTP port
- Does not automatically open SSH, MariaDB, NFS, HTTPS or monitoring ports
- Does not remove existing services or rich rules

Firewall changes require environment-specific source restrictions and network review before production use.

## Prometheus

The monitoring role:

- Requires an existing Prometheus installation
- Requires `promtool`
- Uses file-based target discovery
- Backs up the existing target file
- Validates the complete configuration before reload
- Does not install Prometheus or enable public access

Node Exporter and Prometheus endpoints should be limited to approved monitoring networks.

## Supply-Chain Controls

Development dependencies and Ansible collections are version-pinned.

GitHub Actions:

- Uses read-only repository permissions
- Runs on a fixed Ubuntu runner generation
- Installs pinned Python packages
- Installs the pinned Ansible collection
- Performs YAML, shell, Ansible lint and syntax validation
- Does not deploy infrastructure

Major dependency upgrades require release-note review, compatibility testing and rollback consideration.

## Known Limitations

Passing CI confirms static quality only. It does not prove:

- RHEL runtime compatibility
- Correct SELinux behavior
- Correct firewall policy
- NFS availability
- Database consistency
- Application functionality
- End-to-end high availability
- Security compliance

Live testing requires approved disposable or non-production RHEL systems.
