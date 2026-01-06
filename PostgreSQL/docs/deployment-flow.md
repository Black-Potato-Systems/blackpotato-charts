# Deployment Flow

This document explains how Helm installs and upgrades the PostgreSQL chart, and the order in which Kubernetes resources are created.

## Deployment Process

**Command**: `helm install my-postgres postgresql/ -f values.yaml`

### Step 1: Load and Validate
- Helm reads Chart.yaml metadata
- Loads default values from values.yaml
- Merges with user-provided values
- Runs validation checks from _validations.tpl

### Step 2: Render Templates
- Generates Kubernetes manifests from templates
- Applies conditional logic based on values
- Creates resources: StatefulSet, Service, ConfigMap, Secret
- Optionally creates pgBackRest resources (if enabled)

### Step 3: Apply Resources
Kubernetes resources are created in this order:
1. **ConfigMaps** - PostgreSQL configuration
2. **Secrets** - Database credentials, S3 credentials
3. **RBAC** - ServiceAccount, Role, RoleBinding (if pgBackRest enabled)
4. **Services** - DNS endpoint for PostgreSQL
5. **StatefulSet** - PostgreSQL pod(s)
6. **CronJobs** - Backup schedules (if pgBackRest enabled)

### Step 4: Post-Install Hooks
If pgBackRest is enabled with hooks, a Job runs after installation:
- Waits for PostgreSQL pod to be ready
- Creates pgBackRest stanza
- Runs initial full backup (if none exists)

### Step 5: Display Installation Notes
Helm shows connection information and next steps from NOTES.txt
                    ┌─────────────▼──────────────┐
                    │ 6. Post-install Hooks      │
                    │    - Create stanza         │
                    │    - Initial backups       │
                    │    - Initialization       │
                    └─────────────┬──────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │ 7. Display NOTES.txt       │
                    │    - Connection info       │
                    │    - Next steps            │
                    └─────────────────────────────┘
```

# Deployment Flow

This document explains how Helm installs and upgrades the PostgreSQL chart, and the order in which Kubernetes resources are created.

## Deployment Process

**Command**: `helm install my-postgres postgresql/ -f values.yaml`

### Step 1: Load and Validate
- Helm reads Chart.yaml metadata
- Loads default values from values.yaml
- Merges with user-provided values
- Runs validation checks from _validations.tpl

### Step 2: Render Templates
- Generates Kubernetes manifests from templates
- Applies conditional logic based on values
- Creates resources: StatefulSet, Service, ConfigMap, Secret
- Optionally creates pgBackRest resources (if enabled)

### Step 3: Apply Resources
Kubernetes resources are created in this order:
1. **ConfigMaps** - PostgreSQL configuration
2. **Secrets** - Database credentials, S3 credentials
3. **RBAC** - ServiceAccount, Role, RoleBinding (if pgBackRest enabled)
4. **Services** - DNS endpoint for PostgreSQL
5. **StatefulSet** - PostgreSQL pod(s)
6. **CronJobs** - Backup schedules (if pgBackRest enabled)

### Step 4: Post-Install Hooks
If pgBackRest is enabled with hooks, a Job runs after installation:
- Waits for PostgreSQL pod to be ready
- Creates pgBackRest stanza
- Runs initial full backup (if none exists)

### Step 5: Display Installation Notes
Helm shows connection information and next steps from NOTES.txt

## PostgreSQL Pod Startup

When the StatefulSet creates a pod:

### 1. Init Container (if TLS enabled)
- **Container**: minio-ca-init
- **Purpose**: Install MinIO CA certificate into OS trust store
- **Runs as**: Non-root user (UID 1001)
- **Action**: Copies certificate from Secret to /etc/ssl/certs/

### 2. Main Container Starts
- **Container**: postgresql
- **Image**: aryan/postgres-pgbackrest:15.0
- **Components**: PostgreSQL 15.0 + pgBackRest CLI
- **Configuration**: Loads postgresql.conf from ConfigMap
- **Data Directory**: /var/lib/postgresql/data/pgdata (persistent volume)
- **Credentials**: Loaded from Secret as environment variables

### 3. Health Checks Begin
- **Readiness Probe**: Checks if PostgreSQL accepts connections
- **Liveness Probe**: Monitors PostgreSQL health
- **Command**: pg_isready -U postgres -d myapp -h localhost

### 4. Service Discovery
- Service selector matches pod labels
- DNS endpoint becomes available: postgresql.namespace.svc.cluster.local
- External clients can connect via Service

## Upgrade Workflow

**Command**: `helm upgrade my-postgres postgresql/ -f values.yaml`

### Process:
1. Load new chart and values
2. Validate configuration
3. Render new manifests
4. Compare with existing cluster state
5. Apply changes:
   - ConfigMaps and Secrets are updated
   - StatefulSet spec is modified
   - Kubernetes performs rolling update of pods
6. Post-upgrade hooks execute (if pgBackRest enabled)
7. Display updated notes

### Configuration Changes
When PostgreSQL configuration changes:
- ConfigMap is updated immediately
- Pod must be restarted to apply changes
- Manual restart: `kubectl rollout restart statefulset postgresql`

## Backup System Initialization

If pgBackRest is enabled (`pgbackrest.enabled: true`):

### Post-Install Hook Job
1. **Wait**: Pod must be Running and Ready
2. **Stanza Check**: Verify if pgBackRest stanza exists
3. **Create Stanza**: If missing, create with `pgbackrest stanza-create`
4. **Backup Check**: Query existing backups
5. **Initial Backup**: Run full backup if none exist

### Continuous Operations
After initialization:
- **WAL Archiving**: Continuous (on every transaction commit)
- **Full Backups**: Weekly (Sunday 2 AM by default)
- **Incremental Backups**: Daily (Monday-Saturday 2 AM by default)

## Uninstall Workflow

**Command**: `helm uninstall my-postgres`

### Resources Deleted:
- CronJobs
- StatefulSet and Pods
- Services
- ConfigMaps
- Secrets (except mirrored CA with keep policy)
- RBAC resources

### Resources Retained:
- **PersistentVolumeClaims** - Data is preserved
- **PersistentVolumes** - Depends on StorageClass reclaim policy
- **Backups in S3** - Retained in backup repository

To delete data completely:
- Delete PVCs manually: `kubectl delete pvc --all`
- Clear S3 backup repository

---

**Related Documentation**:
- [Architecture Overview](architecture-overview.md) - Complete system architecture
- [Helm Architecture](helm-architecture.md) - Template structure
- [Values Reference](values-reference.md) - All configuration options



## Key Takeaways

1. **Sequential**: Resources created in dependency order (secrets before pods)
2. **Declarative**: Helm describes desired state; Kubernetes makes it real
3. **Idempotent**: Running install twice = same result
4. **Upgradeable**: Config changes applied without downtime (mostly)
5. **Hooks**: Post-install enables backup system before returning
6. **Scaling**: Only adds more independent instances, not replication
7. **Data Persistence**: PVCs survive pod/pod deletion (by default)

---

**Next Steps**:
- Review [values-reference.md](values-reference.md) for all configuration options
- Check [naming-and-labels.md](naming-and-labels.md) for resource naming conventions
- See [helm-architecture.md](helm-architecture.md) for template structure details
