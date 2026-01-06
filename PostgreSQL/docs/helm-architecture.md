# Helm Architecture

This document explains the structure and organization of the PostgreSQL Helm chart.

## Directory Structure

```
PostgreSQL-Helm/
├── Chart.yaml                          # Chart metadata and version info
├── values.yaml                         # Default configuration values
├── templates/
│   ├── _helpers.tpl                   # Helper template definitions
│   ├── _validations.tpl               # Template validation rules
│   ├── NOTES.txt                      # Post-installation notes
│   ├── database/
│   │   ├── configmap.yaml             # PostgreSQL configuration
│   │   ├── secret.yaml                # PostgreSQL credentials
│   │   ├── service.yaml               # Kubernetes Service for DNS
│   │   └── statefulset.yaml           # StatefulSet for PostgreSQL Pod
│   ├── backup/
│   │   ├── legacy/                    # Deprecated pg_dumpall backups
│   │   │   ├── cronjob.yaml
│   │   │   ├── s3-secret.yaml
│   │   │   └── serviceaccount.yaml
│   │   └── pgbackrest/
│   │       ├── config.yaml            # pgBackRest configuration
│   │       ├── cronjob.yaml           # Scheduled backup jobs
│   │       ├── rbac.yaml              # ServiceAccount and RBAC
│   │       ├── recovery-job.yaml      # Point-in-time recovery job
│   │       ├── s3-secret.yaml         # S3 credentials
│   │       └── hooks/
│   │           ├── job-init.yaml      # Post-install initialization
│   │           └── rbac.yaml          # RBAC for hooks
│   └── pgbackrest/
│       └── minio-ca-secret.yaml       # MinIO CA certificate mirror
```
