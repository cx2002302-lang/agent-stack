#!/usr/bin/env bash
# Zettelkasten Quick Install — one command for AI Agent
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cx2002302-lang/agent-stack/main/packages/zettelkasten/scripts/quick-install.sh | bash
set -euo pipefail

REPO_URL="https://github.com/cx2002302-lang/agent-stack.git"
STACK_DIR="$HOME/.openclaw/agent-stack"

echo "=========================================="
echo "  Zettelkasten — Quick Install"
echo "=========================================="

command -v git  >/dev/null 2>&1 || { echo "Need git"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Need Node.js ≥18"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "Need npm"; exit 1; }

if [ -d "$STACK_DIR/.git" ]; then
  echo "Using existing agent-stack at $STACK_DIR..."
  cd "$STACK_DIR" && git pull --ff-only
else
  echo "Cloning agent-stack to $STACK_DIR..."
  git clone --depth 1 "$REPO_URL" "$STACK_DIR"
fi

cd "$STACK_DIR/packages/zettelkasten"

# ── Install dependencies ──
echo ""
echo "[1/2] Installing npm dependencies..."
npm install
echo "  ✓ npm dependencies installed"

# ── Deploy to OpenClaw ──
echo "[2/2] Deploying to OpenClaw plugin directory..."
ZK_DB="$HOME/.openclaw/zettelkasten/zettelkasten.db"
if [ -f "$ZK_DB" ]; then
  echo "  ⚠ Existing ZK database found — deploying plugin only (skipping init)."
fi
bash scripts/deploy.sh

echo ""
echo "=========================================="
echo "  Zettelkasten installed!"
echo "=========================================="
echo ""
echo "Next steps:"
if [ -f "$ZK_DB" ]; then
  echo "  Verify:     openclaw zk doctor"
  echo ""
  echo "  ⚠ Database exists at:"
  echo "    $ZK_DB"
  echo "    → Do NOT run 'openclaw zk init' — it will drop existing data!"
else
  echo "  Initialize: openclaw zk init"
  echo "  Verify:     openclaw zk doctor"
fi
echo ""
