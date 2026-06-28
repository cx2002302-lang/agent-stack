#!/usr/bin/env bash
# Agent Stack Quick Install — one command for AI Agent
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cx2002302-lang/agent-stack/main/scripts/quick-install.sh | bash
set -euo pipefail

REPO_URL="https://github.com/cx2002302-lang/agent-stack.git"
TARGET="${1:-$HOME/.openclaw/agent-stack}"

echo "=========================================="
echo "  Agent Stack — Quick Install"
echo "=========================================="

# ── Check prerequisites ──
command -v git  >/dev/null 2>&1 || { echo "Need git"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Need Node.js ≥18"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "Need npm"; exit 1; }
command -v pip3 >/dev/null 2>&1 && PIP=pip3 || PIP=pip
command -v python3 >/dev/null 2>&1 || { echo "Need Python ≥3.10"; exit 1; }

# ── Clone or update repo ──
if [ -d "$TARGET/.git" ]; then
  echo "Updating existing install at $TARGET..."
  cd "$TARGET" && git pull --ff-only
else
  echo "Cloning to $TARGET..."
  git clone --depth 1 "$REPO_URL" "$TARGET"
fi

# ── Run install ──
cd "$TARGET"
bash scripts/install.sh

echo ""
echo "=========================================="
echo "  Agent Stack — Ready for Agent!"
echo "=========================================="
echo ""
echo "To verify, tell your agent:"
echo '  svm --version && openclaw zk doctor'
echo ""
