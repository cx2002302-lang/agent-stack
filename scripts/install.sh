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

echo "=========================================="
echo "  Agent Stack installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Initialize Zettelkasten:  cd packages/zettelkasten && bash scripts/deploy.sh"
echo "  2. Verify SVM CLI:            svm --version"
echo "  3. Initialize persona:       cd packages/open-upsp && node dist/cli.js init"
echo ""
echo "See README.md for detailed usage."
