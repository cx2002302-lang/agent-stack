#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo "  Agent Stack — Docker Deployment"
echo "=========================================="
echo ""

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Error: docker is required"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || command -v docker compose >/dev/null 2>&1 || { echo "Error: docker-compose is required"; exit 1; }

echo "Deploying OpenClaw + Hermes containers with SVM and Zettelkasten..."
echo ""
echo "This will start:"
echo "  - hermes-latest     (nousresearch/hermes-agent)"
echo "  - openclaw-latest   (OpenClaw 2026.6.x)"
echo "  - openclaw-2026-4-24  (OpenClaw 2026.4.24)"
echo "  - openclaw-2026-4-23  (OpenClaw 2026.4.23)"
echo ""

# Run docker-compose from the compatibility testing environment
COMPOSE_DIR="$ROOT/../environments/compat-testing"
if [ -f "$COMPOSE_DIR/docker-compose.yml" ]; then
  docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
  echo "✓ Containers started"
else
  echo "Warning: docker-compose.yml not found at $COMPOSE_DIR"
  echo "Please deploy containers manually."
fi
