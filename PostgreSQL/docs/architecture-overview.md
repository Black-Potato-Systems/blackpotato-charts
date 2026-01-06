# PostgreSQL Helm Chart - Architecture Overview

This document provides a detailed technical architecture of the PostgreSQL Helm chart deployment, including all components, their interactions, and data flows.

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [PostgreSQL StatefulSet Pod Architecture](#postgresql-statefulset-pod-architecture)
3. [Backup System Architecture](#backup-system-architecture)
4. [MinIO TLS Certificate Flow](#minio-tls-certificate-flow)
5. [Data Flow Diagrams](#data-flow-diagrams)
6. [Security Architecture](#security-architecture)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                          │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ PostgreSQL Namespace (default)                              │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ StatefulSet: postgresql                          │      │   │
│  │  │  └─ Pod: postgresql-0                            │      │   │
│  │  │     ├─ Init: minio-ca-init (if TLS enabled)      │      │   │
│  │  │     └─ Main: postgresql + pgbackrest             │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ Service: postgresql (ClusterIP)                  │      │   │
│  │  │  └─ Port: 5432 → postgresql-0:5432               │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ PVC: postgresql-storage-postgresql-0             │      │   │
│  │  │  └─ Size: 10Gi (configurable)                    │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ ConfigMaps:                                       │      │   │
│  │  │  ├─ postgresql-config (postgresql.conf)          │      │   │
│  │  │  └─ postgresql-pgbackrest-config (pgbackrest.conf)│     │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ Secrets:                                          │      │   │
│  │  │  ├─ postgresql (DB credentials)                   │      │   │
│  │  │  ├─ postgresql-pgbackrest-s3 (S3 credentials)    │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ CronJobs (if pgbackrest.enabled):                │      │   │
│  │  │  ├─ postgresql-pgbackrest-full (weekly)          │      │   │
│  │  │  └─ postgresql-pgbackrest-incr (daily)           │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  │  ┌──────────────────────────────────────────────────┐      │   │
│  │  │ Hook Job (post-install/post-upgrade):            │      │   │
│  │  │  └─ postgresql-pgbackrest-init                   │      │   │
│  │  │     (Creates stanza, initial backup)             │      │   │
│  │  └──────────────────────────────────────────────────┘      │   │
│  │                                                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS 
                                    ▼
                        ┌───────────────────────┐
                        │ S3-Compatible Storage │
                        │ (MinIO / AWS S3)      │
                        │  └─ Backup Repository │
                        │     - Full backups    │
                        │     - Incremental     │
                        │     - WAL archives    │
                        └───────────────────────┘
```

---

## PostgreSQL StatefulSet Pod Architecture

### Complete Pod Structure

```
┌──────────────────────────────────────────────────────────────────────┐
│ Pod: postgresql-0                                                    │
│ Security Context: runAsUser=999, fsGroup=999 (or 1001 if TLS)       │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────────┐ │
│ │ Init Container: minio-ca-init (conditional: only if TLS)       │ │
│ │ ─────────────────────────────────────────────────────────────  │ │
│ │ Image: aryan/postgres-pgbackrest:15.0 (same as main)          │ │
│ │ Security Context:                                              │ │
│ │   runAsNonRoot: true                                           │ │
│ │   runAsUser: 1001                                              │ │
│ │   runAsGroup: 1001                                             │ │
│ │   allowPrivilegeEscalation: false                              │ │
│ │   capabilities: drop [ALL]                                     │ │
│ │                                                                │ │
│ │ Task:                                                          │ │
│ │   Copy MinIO CA certificate to OS trust store                 │ │
│ │   $ cp /usr/local/share/ca-certificates/minio/tls.crt \       │ │
│ │        /etc/ssl/certs/minio-ca.crt                            │ │
│ │                                                                │ │
│ │ Volume Mounts:                                                 │ │
│ │   ├─ /usr/local/share/ca-certificates/minio (Secret, RO)      │ │
│ │   └─ /etc/ssl/certs (EmptyDir, RW - shared with main)         │ │
│ └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ ┌────────────────────────────────────────────────────────────────┐ │
│ │ Main Container: postgresql                                     │ │
│ │ ─────────────────────────────────────────────────────────────  │ │
│ │ Image: aryan-laptophp/postgres-pgbackrest:15.0                 │ │
│ │                                                                │ │
│ │ Components:                                                    │ │
│ │   ├─ PostgreSQL 15.0 Engine                                   │ │
│ │   ├─ pgBackRest CLI (/usr/bin/pgbackrest)                     │ │
│ │   └─ CA Certificates (system trust store)                     │ │
│ │                                                                │ │
│ │ Configuration:                                                 │ │
│ │   Args: ["-c", "config_file=/etc/postgresql/postgresql.conf"] │ │
│ │                                                                │ │
│ │ PostgreSQL Settings (from ConfigMap):                          │ │
│ │   archive_mode = on                                            │ │
│ │   archive_command = 'pgbackrest --stanza=main archive-push %p'│ │
│ │   wal_level = replica                                          │ │
│ │   max_connections = 100                                        │ │
│ │   shared_buffers = 256MB                                       │ │
│ │   ... (all tuning parameters)                                  │ │
│ │                                                                │ │
│ │ Environment Variables:                                         │ │
│ │   POSTGRES_USER: from Secret (postgresql/username)            │ │
│ │   POSTGRES_PASSWORD: from Secret (postgresql/password)        │ │
│ │   POSTGRES_DB: myapp                                           │ │
│ │   PGDATA: /var/lib/postgresql/data/pgdata                      │ │
│ │   PGBACKREST_REPO1_S3_KEY: from Secret (if S3 enabled)        │ │
│ │   PGBACKREST_REPO1_S3_KEY_SECRET: from Secret (if S3 enabled) │ │
│ │                                                                │ │
│ │ Health Probes:                                                 │ │
│ │   Liveness: pg_isready -U postgres -d myapp (every 10s)       │ │
│ │   Readiness: pg_isready -U postgres -d myapp (every 10s)      │ │
│ │                                                                │ │
│ │ Volume Mounts:                                                 │ │
│ │   ├─ /var/lib/postgresql/data (PVC: postgresql-storage)       │ │
│ │   ├─ /etc/postgresql (ConfigMap: postgresql-config, RO)       │ │
│ │   ├─ /etc/pgbackrest (ConfigMap: pgbackrest-config, RO)       │ │
│ │   ├─ /var/log/pgbackrest (EmptyDir: pgbackrest-log)           │ │
│ │   ├─ /etc/ssl/certs (EmptyDir: shared with init, if TLS)      │ │
│ │   └─ /usr/local/share/ca-certificates/minio (Secret, if TLS)  │ │
│ │                                                                │ │
│ │ Ports:                                                         │ │
│ │   └─ 5432/TCP (postgresql)                                     │ │
│ └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ Volumes (Pod-Level):                                                 │
│   ├─ postgresql-storage (PVC - persistent data)                     │
│   ├─ postgresql-config (ConfigMap - postgresql.conf)                │
│   ├─ pgbackrest-config (ConfigMap - pgbackrest.conf, conditional)   │
│   ├─ pgbackrest-log (EmptyDir - log files, conditional)             │
│   ├─ ssl-certs (EmptyDir - shared CA trust store, conditional)      │
│   └─ minio-ca (Secret - MinIO CA certificate, conditional)          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Volume Mount Details

The PostgreSQL pod uses several volume mounts to manage configuration, data, and security:

- **postgresql-storage**: Persistent volume claim for PostgreSQL data directory (PGDATA)
- **postgresql-config**: ConfigMap containing PostgreSQL configuration file (read-only)
- **pgbackrest-config**: ConfigMap containing pgBackRest configuration (read-only)
- **pgbackrest-log**: EmptyDir for pgBackRest log output
- **ssl-certs**: EmptyDir shared between init and main containers for system CA trust store (TLS only)
- **minio-ca**: Secret containing MinIO CA certificate (read-only, TLS only)

---



### Backup Flow Sequence

```
Time      Event
──────────────────────────────────────────────────────────────────
Install   1. Helm creates ConfigMap (pgbackrest-config)
          2. Helm creates Secret (pgbackrest-s3-credentials)
          4. StatefulSet deployed, PostgreSQL starts
          5. PostgreSQL enables WAL archiving
          
          6. POST-INSTALL HOOK: postgresql-pgbackrest-init Job
             └─ Creates stanza
             └─ Runs initial FULL backup
          
          7. CronJobs created (full + incremental)

Runtime   • Continuous: WAL segments archived to S3 on every commit
          • Weekly: Full backup (Sunday 2 AM)
          • Daily: Incremental backup (Mon-Sat 2 AM)

Upgrade   • POST-UPGRADE HOOK: postgresql-pgbackrest-init Job
             └─ Validates stanza
             └─ Skips backup if valid backup exists
```

---

## MinIO TLS Certificate Flow

### Complete Certificate Chain

```
┌───────────────────────────────────────────────────────────────────┐
│ Step 1: Source Certificate (External MinIO Namespace)            │
│ ─────────────────────────────────────────────────────────────    │
│                                                                   │
│ Namespace: minio                                                  │
│ Secret: minio-tls                                                 │
│   └─ tls.crt: -----BEGIN CERTIFICATE-----                        │
│               MIIDXTCCAkWgAwIBAgIJAI...                           │
│               -----END CERTIFICATE-----                           │
│                                                                   │
│ (Created by MinIO installation - NOT by this chart)              │
└───────────────────────────────────────────────────────────────────┘
                          │
                          │ Helm lookup during install/upgrade
                          ▼
┌───────────────────────────────────────────────────────────────────┐
│ Step 2: Helm Template Rendering                                  │
│ ─────────────────────────────────────────────────────────────    │
│                                                                   │
│                                                                   │
│ Validation:                                                       │
│   ✓ Secret exists in namespace?                                  │
│   ✓ Key 'tls.crt' present?                                       │
│   ✓ Can read certificate data?                                   │
│                                                                   │
│ If validation fails → Helm install ABORTS with error             │
└───────────────────────────────────────────────────────────────────┘
                          │
                          │ Creates mirrored Secret
                          ▼
┌───────────────────────────────────────────────────────────────────┐
│ Step 3: Mirrored Secret (PostgreSQL Namespace)                   │
│ ─────────────────────────────────────────────────────────────    │
│                                                                   │
│ Namespace: default (or PostgreSQL release namespace)             │
│ Secret: postgresql-minio-ca                                       │
│   └─ tls.crt: <base64-encoded certificate>                       │
│                                                                   │
│   (Retained on helm uninstall for safety)
└───────────────────────────────────────────────────────────────────┘
                          │
                          │ Mounted as volume
                          ▼
┌───────────────────────────────────────────────────────────────────┐
│ Step 4: Init Container Installation                              │
│ ─────────────────────────────────────────────────────────────    │
│                                                                   │
│ Container: minio-ca-init                                          │
│ Image: aryan/postgres-pgbackrest:15.0                            │
│                                                                   │
│ Volume Mounts:                                                    │
│   INPUT:  /usr/local/share/ca-certificates/minio/tls.crt (RO)    │
│           └─ From Secret: postgresql-minio-ca                     │
│                                                                   │
│   OUTPUT: /etc/ssl/certs/ (RW)                                    │
│           └─ EmptyDir shared with main container                  │
│                                                                   │
│ Command Executed:                                                 │
│   $ cp /usr/local/share/ca-certificates/minio/tls.crt \          │
│        /etc/ssl/certs/minio-ca.crt                               │
│                                                                   │
│ Result:                                                           │
│   Certificate installed in system trust store                     │
│   (No update-ca-certificates required - direct copy)             │
└───────────────────────────────────────────────────────────────────┘
                          │
                          │ Main container starts
                          ▼
┌───────────────────────────────────────────────────────────────────┐
│ Step 5: Certificate Usage (PostgreSQL Container)                 │
│ ─────────────────────────────────────────────────────────────    │
│                                                                   │
│ Container: postgresql                                             │
│                                                                   │
│ Volume Mount:                                                     │
│   /etc/ssl/certs/ (RW - same EmptyDir as init container)         │
│   └─ minio-ca.crt (installed by init container)                  │
│                                                                   │
│ pgBackRest Operation:                                             │
│   $ pgbackrest backup --stanza=main                              │
│       ↓                                                           │
│   Connects to: https://minio.example.com:9000                    │
│       ↓                                                           │
│   SSL/TLS Handshake                                               │
│       ↓                                                           │
│   Validates server certificate against /etc/ssl/certs/            │
│       ↓                                                           │
│   Finds: minio-ca.crt → ✓ Trusted                                │
│       ↓                                                           │
│   Connection established → Backup proceeds                        │
│                                                                   │
│ pgBackRest Configuration:                                         │
│   repo1-s3-verify-tls=y (enabled by default)                     │
│   (Uses system CA trust store automatically)                     │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### PostgreSQL Write & WAL Archive Flow

```
Application
     │
     │ INSERT/UPDATE/DELETE
     ▼
PostgreSQL Engine (postgresql-0)
     │
     ├─ Write to WAL buffer
     │      ↓
     ├─ Flush WAL to disk
     │      ↓
     ├─ Commit transaction (return success to client)
     │      ↓
     └─ WAL segment full (16MB) → Archive trigger
            ↓
            archive_command triggered
            ↓
            pgBackRest reads WAL file
            ↓
            Compresses (gzip, level 6)
            ↓
            Uploads to S3 repository
            ↓
            Archive complete
```
