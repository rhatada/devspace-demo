#!/bin/bash
set -euo pipefail

echo "=== Act Runner initialization ==="

echo "Waiting for runner token..."
for i in $(seq 1 90); do
  if [ -f /shared/runner-token ]; then
    break
  fi
  if [ "$i" -eq 90 ]; then
    echo "ERROR: Runner token not found. Run init-gitea first."
    exit 1
  fi
  sleep 2
done

TOKEN=$(cat /shared/runner-token | tr -d '[:space:]')
echo "Token received."

echo "Generating runner config..."
mkdir -p /data
cat > /data/config.yaml <<'EOF'
log:
  level: info

runner:
  file: /data/.runner
  capacity: 1
  timeout: 3h
  shutdown_timeout: 3s
  labels:
    - "ubuntu-latest:host"
    - "ubuntu-22.04:host"

cache:
  enabled: true
  dir: /data/cache

host:
  workdir_parent: /data/workdir
EOF

echo "Registering runner with Gitea..."
act_runner register \
  --no-interactive \
  --instance http://localhost:3000 \
  --token "$TOKEN" \
  --name devspace-runner \
  --config /data/config.yaml

echo "Starting runner daemon..."
nohup act_runner daemon --config /data/config.yaml > /data/runner.log 2>&1 &
RUNNER_PID=$!
echo "Runner daemon started (PID: $RUNNER_PID)"

sleep 2
if kill -0 "$RUNNER_PID" 2>/dev/null; then
  echo "=== Act Runner initialization complete ==="
  echo "  Logs: /data/runner.log"
else
  echo "ERROR: Runner daemon failed to start. Check /data/runner.log"
  exit 1
fi
