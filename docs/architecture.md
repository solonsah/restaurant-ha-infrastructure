# Architecture

## Purpose

This project demonstrates a production-oriented Linux framework for operating a restaurant platform across multiple Apache HTTPD nodes with HAProxy load balancing, shared NFS storage, MariaDB connectivity, Prometheus monitoring, controlled automation, validation and rollback safeguards.

It is an infrastructure framework, not a complete restaurant application.

## Logical Request Flow

```text
Private clients
      |
Approved DNS name or virtual IP
      |
HAProxy load-balancing tier
      |
Four Apache HTTPD web nodes
      |                 |
Shared NFS storage      MariaDB service endpoint
      |
Prometheus monitoring
```

## Infrastructure Tiers

### Load-Balancing Tier

Two HAProxy nodes distribute HTTP requests across the Apache HTTPD web tier.

HAProxy:

- Uses least-connections balancing
- Performs HTTP health checks against `/healthz`
- Stops routing traffic to unhealthy web nodes
- Adds forwarding information for backend request handling
- Validates configuration before reload

This repository does not automatically create a floating virtual IP. Production use requires an independently reviewed method such as an existing network load balancer, DNS failover, VRRP or a supported cluster manager.

### Web Tier

Four Apache HTTPD nodes provide horizontally scalable web capacity.

The supplied configuration:

- Does not assume Nginx
- Does not assume PHP
- Disables directory listing
- Provides a dedicated health-check file
- Adds basic defensive response headers
- Reloads HTTPD only after configuration validation

Application code, runtime dependencies and session behavior must be assessed separately.

### Shared-Storage Tier

Web nodes can mount a shared NFS path for approved content that must be consistent across the tier.

The NFS client configuration uses:

- Persistent `/etc/fstab` management
- `_netdev` for network-dependent mounting
- `nosuid` and `nodev` safety options
- A dedicated mount path

A single NFS server is a single point of failure. A production design must use an approved resilient NFS service, clustered storage, replicated storage or another application-appropriate shared-data strategy.

### Database Tier

The framework validates TCP connectivity to a MariaDB service endpoint. It does not store credentials, create databases, clone production data or alter database schemas.

A single MariaDB server is also a single point of failure. Production high availability requires a separately designed and tested database architecture, backups, recovery procedures and consistency controls.

### Monitoring Tier

Prometheus file-based discovery is generated from the Ansible inventory. Infrastructure nodes are expected to expose approved Node Exporter endpoints.

The role:

- Requires an existing Prometheus installation
- Backs up the current target file
- Validates the complete Prometheus configuration with `promtool`
- Requests a reload only after validation

## Availability Boundaries

Multiple web nodes alone do not make the complete service highly available. End-to-end availability depends on:

- Client access and DNS or virtual-IP availability
- Load-balancer redundancy
- Web-node health and application statelessness
- Shared-storage resilience
- Database resilience
- Network paths
- Monitoring and alerting
- Tested recovery procedures

## Security Boundaries

The framework intentionally excludes:

- Credentials and private keys
- Real hostnames, domains and IP addresses
- TLS certificates
- Database dumps
- Production inventories
- Application secrets
- Unreviewed firewall changes
- Automatic production deployment

All example addresses use IANA documentation ranges.
