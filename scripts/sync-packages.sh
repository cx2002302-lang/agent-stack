#!/usr/bin/env bash
# sync-packages.sh — 检查/同步 agent-stack 子包与 standalone 仓库的漂移
#
# 用法:
#   scripts/sync-packages.sh           # 检查模式（默认）：只报告漂移，退出码 1 表示有漂移
#   scripts/sync-packages.sh --apply   # 同步模式：把 standalone 的源码目录 rsync 进 packages/
#
# 同步范围（与 P1-3 修复口径一致，只覆盖源码目录，不覆盖各自 package.json/pyproject.toml）:
#   zettelkasten: standalone src/   -> packages/zettelkasten/src/   （含全部 __tests__/ 与 mcp/http-bridge.ts）
#   memory-plus:  standalone svm/   -> packages/memory-plus/svm/
#   open-upsp:    standalone src/、tests/ -> packages/open-upsp/{src,tests}/
#
# 版本号只做提示（⚠️），不影响退出码：
#   zettelkasten standalone 以 git tag 为准（v1.0.0-beta.10），其 package.json 停留在 beta.8，
#   与本包 package.json（beta.10）的"不一致"是已知状态，故版本漂移不判失败。
#
# 环境变量可覆盖 standalone 路径:
#   ZK_STANDALONE / MP_STANDALONE / UPSP_STANDALONE

set -euo pipefail

AGENT_STACK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZK_STANDALONE="${ZK_STANDALONE:-$HOME/.openclaw/project/zettelkasten}"
MP_STANDALONE="${MP_STANDALONE:-$HOME/.openclaw/project/memory_plus}"
UPSP_STANDALONE="${UPSP_STANDALONE:-$HOME/.openclaw/project/open_upsp}"

MODE=check
if [[ "${1:-}" == "--apply" ]]; then
  MODE=apply
elif [[ -n "${1:-}" ]]; then
  echo "未知参数: $1（仅支持 --apply）" >&2
  exit 2
fi

drift=0

# 子包刻意保留、不存在于 standalone 的本地文件（按 basename 排除），不参与漂移判定与 --delete。
# smoke.test.ts 是 P1-7 补的兜底 smoke 层，专门覆盖 ZettelkastenClient 门面，有意仅存在于本包。
ZK_LOCAL_ONLY=("smoke.test.ts")

# sync_dir <src> <dst> <label> [exclude ...]
sync_dir() {
  local src="$1" dst="$2" label="$3"
  shift 3
  if [[ ! -d "$src" ]]; then
    echo "⚠️  $label: standalone 源目录不存在: $src"
    return
  fi
  if diff -rq "$src" "$dst" --exclude=__pycache__ "$@" >/dev/null 2>&1; then
    echo "✅ $label: 一致"
    return
  fi
  if [[ "$MODE" == "apply" ]]; then
    mkdir -p "$dst"
    rsync -a --delete --exclude=__pycache__ "$@" "$src/" "$dst/"
    echo "🔄 $label: 已同步"
  else
    drift=1
    echo "❌ $label: 有漂移（运行 $0 --apply 同步）"
    diff -rq "$src" "$dst" --exclude=__pycache__ "$@" 2>/dev/null | head -20 | sed 's/^/     /'
  fi
}

json_ver() { grep -m1 '"version"' "$1" 2>/dev/null | sed -E 's/.*"version" *: *"([^"]+)".*/\1/'; }
toml_ver() { grep -m1 '^version' "$1" 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/'; }

# check_version <standalone_file> <package_file> <label> <extractor>
check_version() {
  local sf="$1" pf="$2" label="$3" ex="$4"
  local sv pv
  sv="$("$ex" "$sf")"
  pv="$("$ex" "$pf")"
  if [[ -z "$sv" || -z "$pv" ]]; then
    echo "⚠️  $label: 无法读取版本号（standalone='$sv' package='$pv'）"
  elif [[ "$sv" == "$pv" ]]; then
    echo "✅ $label: 版本一致 ($pv)"
  else
    echo "⚠️  $label: 版本不同 standalone=$sv package=$pv（仅提示，不判漂移）"
  fi
}

echo "==> zettelkasten (standalone: $ZK_STANDALONE)"
zk_excludes=()
for f in "${ZK_LOCAL_ONLY[@]}"; do zk_excludes+=(--exclude="$f"); done
sync_dir "$ZK_STANDALONE/src" "$AGENT_STACK/packages/zettelkasten/src" "zettelkasten src/" "${zk_excludes[@]}"
check_version "$ZK_STANDALONE/package.json" "$AGENT_STACK/packages/zettelkasten/package.json" "zettelkasten" json_ver

echo "==> memory-plus (standalone: $MP_STANDALONE)"
sync_dir "$MP_STANDALONE/svm" "$AGENT_STACK/packages/memory-plus/svm" "memory-plus svm/"
check_version "$MP_STANDALONE/pyproject.toml" "$AGENT_STACK/packages/memory-plus/pyproject.toml" "memory-plus" toml_ver

echo "==> open-upsp (standalone: $UPSP_STANDALONE)"
sync_dir "$UPSP_STANDALONE/src" "$AGENT_STACK/packages/open-upsp/src" "open-upsp src/"
sync_dir "$UPSP_STANDALONE/tests" "$AGENT_STACK/packages/open-upsp/tests" "open-upsp tests/"
check_version "$UPSP_STANDALONE/package.json" "$AGENT_STACK/packages/open-upsp/package.json" "open-upsp" json_ver

echo
if [[ "$drift" -eq 1 ]]; then
  echo "存在漂移。执行同步: $0 --apply"
  exit 1
fi
if [[ "$MODE" == "apply" ]]; then
  echo "同步完成。注意：若 standalone 的依赖（package.json/pyproject.toml）有变化，"
  echo "请手动同步依赖声明并在对应子包重新安装（npm install / pip install）。"
else
  echo "全部子包源码一致。"
fi
