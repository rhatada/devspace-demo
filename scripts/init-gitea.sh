#!/bin/bash
set -euo pipefail

echo "=== Gitea initialization ==="

echo "Waiting for PostgreSQL..."
for i in $(seq 1 60); do
  if pg_isready -h localhost -p 5432 -U gitea >/dev/null 2>&1; then
    echo "PostgreSQL is ready."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "ERROR: PostgreSQL did not become ready in time."
    exit 1
  fi
  sleep 2
done

echo "Waiting for Gitea API..."
for i in $(seq 1 60); do
  if curl -sf http://localhost:3000/api/v1/version >/dev/null 2>&1; then
    echo "Gitea API is ready."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "ERROR: Gitea API did not become ready in time."
    exit 1
  fi
  sleep 2
done

echo "Creating admin user..."
gitea admin user create \
  --admin \
  --username admin \
  --password admin123 \
  --email admin@local.dev \
  --must-change-password=false 2>/dev/null || echo "(admin user may already exist)"

echo "Generating runner registration token..."
TOKEN=$(gitea actions generate-runner-token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to generate runner token."
  exit 1
fi
echo "$TOKEN" > /shared/runner-token
echo "Runner token saved to /shared/runner-token"

echo "=== Gitea initialization complete ==="
echo "  Web UI: http://localhost:3000"
echo "  Login:  admin / admin123"
