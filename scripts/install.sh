#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "=========================================="
echo "  Agent Stack — One-Click Install"
echo "=========================================="
echo ""

# ── Zettelkasten ──
echo "[1/3] Installing Zettelkasten (npm)..."
cd "$ROOT/packages/zettelkasten"
npm install
echo "  ✓ Zettelkasten installed"
echo ""

# ── Memory Plus ──
echo "[2/3] Installing Memory Plus (pip)..."
cd "$ROOT/packages/memory-plus"
pip install -e ".[test]" 2>/dev/null || pip install --break-system-packages -e ".[test]"
echo "  ✓ Memory Plus installed"
echo ""

# ── open-upsp ──
echo "[3/3] Installing open-upsp (npm + build)..."
cd "$ROOT/packages/open-upsp"
npm install
npm run build
echo "  ✓ open-upsp installed"
echo ""

ZK_DB="$HOME/.openclaw/zettelkasten/zettelkasten.db"
ZK_EXISTS=0
if [ -f "$ZK_DB" ]; then
  ZK_EXISTS=1
  echo "  ⚠ Found existing Zettelkasten database at:"
  echo "    $ZK_DB"
  echo "    → Skipping initialization to preserve existing data."
fi

echo ""
echo "=========================================="
echo "  Agent Stack installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
if [ "$ZK_EXISTS" -eq 0 ]; then
  echo "  1. Initialize Zettelkasten:  cd packages/zettelkasten && bash scripts/deploy.sh"
else
  echo "  1. Zettelkasten database exists — skip init and verify:  openclaw zk doctor"
fi
echo "  2. Verify SVM CLI:            svm --version"
echo "  3. Verify SVM↔ZK sync:        svm sync-status"
echo "  4. Initialize persona:       cd packages/open-upsp && node dist/cli.js init"
echo ""
echo "⚠ IMPORTANT: Never run 'openclaw zk init' on an existing database."
echo "  It will recreate the zettel_notes table and DROP all your data!"
echo ""
echo "See README.md for detailed usage."
