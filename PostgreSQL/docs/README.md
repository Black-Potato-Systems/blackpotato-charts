# PostgreSQL Helm Chart Documentation

Welcome to the PostgreSQL Helm Chart documentation. This guide provides comprehensive information for platform engineers and DevOps teams deploying and managing PostgreSQL on Kubernetes using this Helm chart.

## Chart Overview

This Helm chart deploys a **PostgreSQL database** on Kubernetes with the following capabilities:

- **StatefulSet-based deployment** 
- **PostgreSQL 15.0** with custom image
- **pgBackRest integration** for backup and recovery (optional) - under development
- **S3-compatible storage** support (AWS S3, MinIO)
- **Point-in-Time Recovery (PITR)** capabilities via pgBackRest - under development testing
- **Resource management** with CPU and memory limits
- **Persistent storage** with configurable storage classes

## Chart Metadata

- **Chart Name**: postgresql
- **Chart Version**: 0.1.0
- **App Version**: custom image postrgesql version 15.0
- **Type**: Application (Kubernetes deployment)

## Documentation Structure

This documentation is organized into the following sections:

### 1. [Architecture Overview](architecture-overview.md)
Complete system architecture with detailed diagrams:
- High-level architecture
- PostgreSQL StatefulSet pod structure
- Backup system architecture (pgBackRest)
- MinIO TLS certificate flow
- Data flow diagrams
- Security architecture

### 2. [Helm Architecture](helm-architecture.md)
Understand the overall structure of the Helm chart, including:
- Directory and file organization
- Template system overview
- Helper functions and labels
- Conditional template rendering

### 3. [Deployment Flow](deployment-flow.md)
Learn how Kubernetes manifests are deployed:
- Helm install/upgrade workflow
- Resource creation order
- StatefulSet initialization
- Service discovery and networking

### 4. [Values Reference](values-reference.md)
Complete reference for all configurable parameters:
- PostgreSQL configuration options
- Storage and persistence settings
- Service and networking configuration
- pgBackRest backup settings
- S3 repository configuration
- Security and pod settings
- Resource requests and limits

### 5. [Pending Features & Tasks](PENDING.md)
Track pending features and decisions:
- Documentation gaps (recovery guide, custom image)
- Security concerns (default password)
- Feature decisions (legacy backup system)
- Technical debt tracking
- Release roadmap

## Quick Start

### Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.0+
- Storage class available (for persistence)

### Basic Installation

The chart can be installed using Helm with default values or custom configuration files. After installation, verify the deployment by checking pods, persistent volume claims, and services.

### Accessing PostgreSQL

After installation, connect to PostgreSQL by retrieving credentials from the secret, forwarding the service port, and using a PostgreSQL client.

### Check PostgreSQL Status

Monitor PostgreSQL by viewing pod logs, accessing the pod shell, or testing connectivity from a debug pod within the cluster.

## Key Features

### 1. StatefulSet Deployment
The chart uses a Kubernetes **StatefulSet** instead of Deployment because:
- PostgreSQL requires stable hostname for networking
- Persistent data must correlate with a specific pod
- Ordinal index (-0, -1, etc.) provides predictable naming

### 2. Persistent Storage
By default, persistence is enabled with:
- Storage class: Cluster default (configurable)
- Size: 10Gi (customizable)
- Mount path: `/var/lib/postgresql/data`
- Access mode: ReadWriteOnce (single pod)

### 3. Security
- Non-root user execution (UID 999)
- Read-only config mounts
- Secret management for credentials
- Optional Security Policy integration

### 4. Backup and Recovery
The chart supports two backup mechanisms:

#### pgBackRest (Recommended)
- Continuous WAL archiving to S3
- Full, incremental, and differential backups
- Point-in-Time Recovery (PITR)
- Compression and parallel processing

#### Legacy Backup (pg_dumpall)
- Database-level backups
- Full database dumps to S3
- Retained for backward compatibility

### 5. Health Monitoring
Kubernetes probes automatically:
- **Liveness Probe**: Restarts unhealthy pods
- **Readiness Probe**: Marks pod ready when accepting connections

## Common Tasks

### Enable pgBackRest Backup
Enable pgBackRest in your values file by setting the pgbackrest.enabled flag, configuring S3 settings including bucket and region, providing credentials, and defining backup schedules for full and incremental backups. Apply changes by upgrading the Helm release.

### Scale PostgreSQL Replicas

Adjust the replicaCount value in your configuration file.

⚠️ **Note**: PostgreSQL itself does not replicate data in this chart. A StatefulSet with multiple replicas creates independent PostgreSQL instances, not a replicated cluster. Use additional solutions (Patroni, etc.) for HA replication.

### Modify PostgreSQL Configuration

Edit the postgresql.config section in values.yaml to adjust settings like maxConnections, sharedBuffers, and other PostgreSQL parameters. Apply changes by upgrading the Helm release.

### Point-in-Time Recovery

Enable pgBackRest restore mode in your values file by setting the pgbackrest.restore.enabled flag. Apply the configuration and monitor the pod logs to track the recovery process.

## Configuration Best Practices

1. **Always change the default password** - Set a strong, random password in the postgresql.password field
2. **Enable pgBackRest** for production deployments
3. **Use external S3 bucket** (AWS, MinIO) for backup storage
4. **Set appropriate resource limits** based on workload
5. **Enable TLS** for MinIO endpoints
6. **Use named releases** for easier identification during installation

## Troubleshooting

### Pod Not Starting
Describe the pod and check logs to identify startup issues.

### PVC Not Bound
List and describe persistent volume claims to diagnose storage binding problems.

### Backup Failures
Check backup job logs and verify pgBackRest status using info commands.

### Connection Issues
Test database connectivity from another pod within the cluster using a debug container.

## Related Documentation

- [Helm Official Documentation](https://helm.sh/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgBackRest Documentation](https://pgbackrest.org/user-guide.html)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

## Support and Contributions

For issues, questions, or contributions:
- Review the chart source code in this repository
- Check existing Kubernetes events and logs
- Consult PostgreSQL and pgBackRest official documentation

---

**Last Updated**: January 4, 2026  
**Chart Version**: 0.1.0
