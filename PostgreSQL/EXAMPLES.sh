#!/bin/bash
# PostgreSQL Helm Chart - Example Deployments
# This file contains ready-to-use helm deployment commands

# ============================================================================
# BASIC DEPLOYMENTS
# ============================================================================

# 1. Minimal installation with defaults
echo "=== Example 1: Minimal Installation ==="
echo "helm install postgresql ./postgresql-helm-chart -n default"
echo ""

# 2. With custom namespace
echo "=== Example 2: Custom Namespace ==="
echo "kubectl create namespace databases"
echo "helm install postgresql ./postgresql-helm-chart -n databases"
echo ""

# ============================================================================
# DEVELOPMENT ENVIRONMENTS
# ============================================================================

# 3. Development setup (small resources, no backups)
echo "=== Example 3: Development Setup ==="
echo "helm install postgresql-dev ./postgresql-helm-chart \\"
echo "  --set postgresql.password='dev-password' \\"
echo "  --set persistence.size='5Gi' \\"
echo "  --set resources.requests.memory='256Mi' \\"
echo "  --set resources.requests.cpu='100m' \\"
echo "  --set resources.limits.memory='512Mi' \\"
echo "  --set resources.limits.cpu='500m' \\"
echo "  -n development"
echo ""

# ============================================================================
# pgBackRest WITH S3 DEPLOYMENTS
# ============================================================================

# 4. pgBackRest with AWS S3
echo "=== Example 4: pgBackRest with AWS S3 ==="
echo "helm install postgresql ./postgresql-helm-chart \\"
echo "  --set pgbackrest.enabled=true \\"
echo "  --set pgbackrest.s3.enabled=true \\"
echo "  --set pgbackrest.s3.bucket='my-postgresql-backups' \\"
echo "  --set pgbackrest.s3.region='us-east-1' \\"
echo "  --set pgbackrest.s3.credentials.accessKeyId='YOUR_AWS_KEY_ID' \\"
echo "  --set pgbackrest.s3.credentials.secretAccessKey='YOUR_AWS_SECRET' \\"
echo "  -n default"
echo ""

# 5. pgBackRest with MinIO (S3-compatible)
echo "=== Example 5: pgBackRest with MinIO ==="
echo "helm install postgresql ./postgresql-helm-chart \\"
echo "  --set pgbackrest.enabled=true \\"
echo "  --set pgbackrest.s3.enabled=true \\"
echo "  --set pgbackrest.s3.bucket='postgresql-backups' \\"
echo "  --set pgbackrest.s3.endpoint='https://minio.example.com' \\"
echo "  --set pgbackrest.s3.credentials.accessKeyId='minioadmin' \\"
echo "  --set pgbackrest.s3.credentials.secretAccessKey='minioadmin-secret' \\"
echo "  -n default"
echo ""

# 6. pgBackRest with custom backup schedule
echo "=== Example 6: pgBackRest with Custom Schedule ==="
echo "helm install postgresql ./postgresql-helm-chart \\"
echo "  --set pgbackrest.enabled=true \\"
echo "  --set pgbackrest.s3.enabled=true \\"
echo "  --set pgbackrest.s3.bucket='backups' \\"
echo "  --set 'pgbackrest.backup.fullSchedule=0 1 * * 0' \\"
echo "  --set 'pgbackrest.backup.incrementalSchedule=0 2 * * 1-6' \\"
echo "  --set pgbackrest.backup.retentionFull=14 \\"
echo "  --set pgbackrest.compression='zst' \\"
echo "  --set pgbackrest.compressionLevel=3 \\"
echo "  -n production"
echo ""

# ============================================================================
# PRODUCTION DEPLOYMENTS
# ============================================================================

# 7. Production with large storage and pgBackRest
echo "=== Example 7: Production Setup (Large) ==="
echo "helm install postgresql ./postgresql-helm-chart \\"
echo "  --set postgresql.password='SECURE_PASSWORD' \\"
echo "  --set postgresql.database='production' \\"
echo "  --set persistence.size='100Gi' \\"
echo "  --set persistence.storageClass='ebs-fast' \\"
echo "  --set resources.requests.memory='2Gi' \\"
echo "  --set resources.requests.cpu='1000m' \\"
echo "  --set resources.limits.memory='8Gi' \\"
echo "  --set resources.limits.cpu='4000m' \\"
echo "  --set pgbackrest.enabled=true \\"
echo "  --set pgbackrest.s3.enabled=true \\"
echo "  --set pgbackrest.s3.bucket='prod-backups' \\"
echo "  --set pgbackrest.s3.region='us-east-1' \\"
echo "  --set pgbackrest.s3.credentials.accessKeyId='KEY' \\"
echo "  --set pgbackrest.s3.credentials.secretAccessKey='SECRET' \\"
echo "  --set pgbackrest.backup.retentionFull=30 \\"
echo "  --set pgbackrest.parallelProcess=8 \\"
echo "  -n production"
echo ""

# 8. High performance with both backup strategies
echo "=== Example 8: High Performance (pgBackRest + pg_dumpall) ==="
echo "helm install postgresql ./postgresql-helm-chart \\"
echo "  --set persistence.size='200Gi' \\"
echo "  --set resources.limits.memory='16Gi' \\"
echo "  --set resources.limits.cpu='8000m' \\"
echo "  --set pgbackrest.enabled=true \\"
echo "  --set pgbackrest.s3.enabled=true \\"
echo "  --set pgbackrest.backup.retentionFull=30 \\"
echo "  --set backup.enabled=true \\"
echo "  --set backup.s3.enabled=true \\"
echo "  --set backup.s3.bucket='supplemental-dumps' \\"
echo "  --set backup.retentionDays=14 \\"
echo "  -n production"
echo ""

# ============================================================================
# USING VALUES FILE
# ============================================================================

# 9. Using values file (recommended for complex setups)
echo "=== Example 9: Using Values File ==="
echo "# Create values-prod.yaml with your configuration"
echo "helm install postgresql ./postgresql-helm-chart -f values-prod.yaml -n production"
echo ""

# ============================================================================
# COMMON OPERATIONS
# ============================================================================

# 10. Upgrade existing release
echo "=== Example 10: Upgrade Existing Release ==="
echo "helm upgrade postgresql ./postgresql-helm-chart \\"
echo "  --set persistence.size='50Gi' \\"
echo "  --set resources.limits.memory='4Gi'"
echo ""

# 11. Check release status
echo "=== Example 11: Check Release Status ==="
echo "helm status postgresql"
echo "helm get values postgresql"
echo ""

# 12. Uninstall release
echo "=== Example 12: Uninstall Release ==="
echo "helm uninstall postgresql"
echo "# Note: PVCs are NOT deleted. Delete manually if needed:"
echo "kubectl delete pvc -l app.kubernetes.io/instance=postgresql"
echo ""

# ============================================================================
# VERIFICATION COMMANDS
# ============================================================================

# 13. Verify installation
echo "=== Example 13: Verify Installation ==="
echo "# Check pods"
echo "kubectl get pods -l app.kubernetes.io/name=postgresql"
echo ""
echo "# Check services"
echo "kubectl get svc postgresql"
echo ""
echo "# Check CronJobs (if backups enabled)"
echo "kubectl get cronjob | grep pgbackrest"
echo ""
echo "# View installation notes"
echo "helm get notes postgresql"
echo ""

# ============================================================================
# ACCESS AND TESTING
# ============================================================================

# 14. Connect to PostgreSQL
echo "=== Example 14: Connect to PostgreSQL ==="
echo "# Option 1: Port forward"
echo "kubectl port-forward svc/postgresql 5432:5432"
echo "psql -h localhost -U postgres -d myapp"
echo ""
echo "# Option 2: From another pod"
echo "kubectl run -it --rm psql --image=postgres:15.0 -- \\"
echo "  psql -h postgresql.default.svc.cluster.local -U postgres -d myapp"
echo ""

# 15. Check backups
echo "=== Example 15: Check Backups ==="
echo "kubectl exec postgresql-0 -- pgbackrest info --stanza=main"
echo ""

# 16. Create manual backup
echo "=== Example 16: Create Manual Backup ==="
echo "kubectl exec postgresql-0 -- pgbackrest backup --stanza=main --type=full"
echo ""

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# 17. Troubleshooting commands
echo "=== Example 17: Troubleshooting ==="
echo "# View pod logs"
echo "kubectl logs postgresql-0"
echo ""
echo "# Describe pod"
echo "kubectl describe pod postgresql-0"
echo ""
echo "# Check events"
echo "kubectl get events | grep postgresql"
echo ""
echo "# Check PVC status"
echo "kubectl get pvc"
echo ""
echo "# Test S3 connectivity (if pgBackRest enabled)"
echo "kubectl exec postgresql-0 -- aws s3 ls s3://my-bucket/"
echo ""

# ============================================================================
# HELM COMMANDS
# ============================================================================

# 18. Helm debugging
echo "=== Example 18: Helm Debugging ==="
echo "# Dry run (preview what will be installed)"
echo "helm install postgresql ./postgresql-helm-chart --dry-run --debug"
echo ""
echo "# Template rendering"
echo "helm template postgresql ./postgresql-helm-chart"
echo ""
echo "# Check chart for errors"
echo "helm lint ./postgresql-helm-chart"
echo ""
echo "# Get chart values schema"
echo "helm show values ./postgresql-helm-chart"
echo ""
