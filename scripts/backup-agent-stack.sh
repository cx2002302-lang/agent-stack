#!/usr/bin/env bash
# backup-agent-stack.sh — agent-stack 全量备份
#
# 复刻 2026-07-18 手动备份逻辑（见 ~/.openclaw/backups/agent-stack-full-20260718_235115/BACKUP_README.md），
# 对应体检报告 P2-6「备份策略自动化」。建议纳入 cron（如每周日凌晨 2 点）：
#   0 2 * * 0 ~/.openclaw/project/agent-stack/scripts/backup-agent-stack.sh >> ~/.openclaw/backups/cron.log 2>&1
#
# 用法:
#   scripts/backup-agent-stack.sh              # 全量备份到 $BACKUP_ROOT/agent-stack-full-<时间戳>/
#
# 备份内容（与手动备份一致）:
#   config/   openclaw.json + openclaw-gateway.service
#   data/     zettelkasten / openupsp / svm 数据目录（*.db 一律用 sqlite3 .backup 做一致性拷贝，
#             不复制 -wal/-shm；其余文件原样复制）
#   skills/   ~/.openclaw/skills/ 全量
#   plugin/   ~/.openclaw/zettelkasten-plugin/ 全量
#   source/   agent-stack + zettelkasten 源码（排除 .git/node_modules/.venv 等衍生目录）
#   logs/     /tmp/openclaw/*.log
# 收尾: 对每个备份出的 db 跑 PRAGMA integrity_check，生成 SHA256SUMS 与 BACKUP_README.md，
#       打 tar.gz 归档（附 .sha256），最后按 KEEP_FULL 清理旧备份。
#
# 环境变量:
#   OPENCLAW_HOME    默认 ~/.openclaw
#   BACKUP_ROOT      默认 $OPENCLAW_HOME/backups
#   KEEP_FULL        保留的全量备份份数，默认 3（超出即删除最旧的目录+归档）
#   AGENT_STACK_SRC  默认 ~/.openclaw/project/agent-stack
#   ZK_SRC           默认 ~/.openclaw/project/zettelkasten

set -euo pipefail
trap 'echo "❌ 备份失败：${NAME:-unknown}（${DEST:-} 可能不完整，请人工检查）" >&2' ERR

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
BACKUP_ROOT="${BACKUP_ROOT:-$OPENCLAW_HOME/backups}"
KEEP_FULL="${KEEP_FULL:-3}"
AGENT_STACK_SRC="${AGENT_STACK_SRC:-$OPENCLAW_HOME/project/agent-stack}"
ZK_SRC="${ZK_SRC:-$OPENCLAW_HOME/project/zettelkasten}"

NAME="agent-stack-full-$(date +%Y%m%d_%H%M%S)"
DEST="$BACKUP_ROOT/$NAME"

for cmd in sqlite3 tar sha256sum rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ 缺少命令: $cmd" >&2; exit 1; }
done
# 关键数据源必须存在，否则没有备份意义
[[ -f "$OPENCLAW_HOME/openclaw.json" ]] || { echo "❌ 缺少 $OPENCLAW_HOME/openclaw.json" >&2; exit 1; }
[[ -f "$OPENCLAW_HOME/zettelkasten/zettelkasten.db" ]] || { echo "❌ 缺少 zettelkasten.db" >&2; exit 1; }

echo "==> 创建备份目录: $DEST"
mkdir -p "$DEST"/{config,data,skills,plugin,source,logs}

# copy_data_dir <src> <dst> <label>
# 数据目录复制：普通文件 rsync 原样复制；*.db 用 sqlite3 .backup 做在线一致性拷贝。
copy_data_dir() {
  local src="$1" dst="$2" label="$3"
  if [[ ! -d "$src" ]]; then
    echo "⚠️  $label: 源目录不存在，跳过: $src"
    return 0
  fi
  mkdir -p "$dst"
  rsync -a --exclude='*.db' --exclude='*.db-shm' --exclude='*.db-wal' "$src/" "$dst/"
  local db base
  while IFS= read -r -d '' db; do
    base="$(basename "$db")"
    sqlite3 "$db" ".backup '$dst/$base'"
    echo "✅ $label: $base（sqlite3 .backup 一致性拷贝）"
  done < <(find "$src" -maxdepth 1 -name '*.db' -print0)
  echo "✅ $label: 已复制 -> $dst"
}

echo "==> [1/7] config"
cp -a "$OPENCLAW_HOME/openclaw.json" "$DEST/config/"
if [[ -f "$HOME/.config/systemd/user/openclaw-gateway.service" ]]; then
  cp -a "$HOME/.config/systemd/user/openclaw-gateway.service" "$DEST/config/"
else
  echo "⚠️  未找到 openclaw-gateway.service，跳过"
fi

echo "==> [2/7] data/zettelkasten"
copy_data_dir "$OPENCLAW_HOME/zettelkasten" "$DEST/data/zettelkasten" "zettelkasten"

echo "==> [3/7] data/openupsp + data/svm"
copy_data_dir "$OPENCLAW_HOME/openupsp" "$DEST/data/openupsp" "openupsp"
copy_data_dir "$OPENCLAW_HOME/svm" "$DEST/data/svm" "svm"

echo "==> [4/7] skills"
rsync -a "$OPENCLAW_HOME/skills/" "$DEST/skills/"
echo "✅ skills 已复制"

echo "==> [5/7] plugin/zettelkasten-plugin"
if [[ -d "$OPENCLAW_HOME/zettelkasten-plugin" ]]; then
  rsync -a "$OPENCLAW_HOME/zettelkasten-plugin" "$DEST/plugin/"
  echo "✅ plugin 已复制"
else
  echo "⚠️  未找到 zettelkasten-plugin，跳过"
fi

echo "==> [6/7] source（排除 .git/node_modules/.venv 等）"
SRC_EXCLUDES=(--exclude=.git --exclude=node_modules --exclude=.venv --exclude=__pycache__ --exclude=.local)
[[ -d "$AGENT_STACK_SRC" ]] && rsync -a "${SRC_EXCLUDES[@]}" "$AGENT_STACK_SRC" "$DEST/source/" || echo "⚠️  未找到 $AGENT_STACK_SRC，跳过"
[[ -d "$ZK_SRC" ]] && rsync -a "${SRC_EXCLUDES[@]}" "$ZK_SRC" "$DEST/source/" || echo "⚠️  未找到 $ZK_SRC，跳过"

echo "==> [7/7] logs"
if compgen -G "/tmp/openclaw/*.log" >/dev/null; then
  cp -a /tmp/openclaw/*.log "$DEST/logs/"
  echo "✅ 日志已复制"
else
  echo "⚠️  /tmp/openclaw 下无日志文件"
fi

echo "==> 数据库完整性校验"
db_ok=1
while IFS= read -r -d '' db; do
  if [[ "$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>/dev/null)" == "ok" ]]; then
    echo "✅ integrity_check ok: ${db#"$DEST"/}"
  else
    echo "❌ integrity_check 失败: ${db#"$DEST"/}" >&2
    db_ok=0
  fi
done < <(find "$DEST/data" -name '*.db' -print0)
[[ "$db_ok" -eq 1 ]] || { echo "❌ 备份数据库校验未通过，中止（保留 $DEST 供排查）" >&2; exit 1; }

echo "==> 生成 SHA256SUMS"
(cd "$DEST" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)

file_count="$(find "$DEST" -type f | wc -l)"
dir_size="$(du -sh "$DEST" | cut -f1)"

echo "==> 生成 BACKUP_README.md"
cat > "$DEST/BACKUP_README.md" <<EOF
# agent-stack 全量备份说明

- **备份名称**: $NAME
- **备份时间**: $(date '+%Y-%m-%d %H:%M:%S (%Z)')
- **备份主机**: $(hostname)
- **备份用户**: $(whoami)
- **生成方式**: scripts/backup-agent-stack.sh（自动化，逻辑同 2026-07-18 手动备份）

## 备份内容清单

- \`config/\` — openclaw.json、openclaw-gateway.service
- \`data/zettelkasten/\` — notes/、zettelkasten.db（sqlite3 .backup 一致性拷贝）、导出文件
- \`data/openupsp/\` — Open_USP 配置与位格数据
- \`data/svm/\` — SVM 数据库（sqlite3 .backup 一致性拷贝）与运行时数据
- \`skills/\` — ~/.openclaw/skills/ 全量
- \`plugin/\` — zettelkasten-plugin 全量
- \`source/\` — agent-stack 与 zettelkasten 源码（排除 .git/node_modules 等）
- \`logs/\` — /tmp/openclaw/ 运行日志

## 校验信息

- **备份目录总大小**: $dir_size
- **文件总数**: $file_count
- **校验文件**: SHA256SUMS（sha256sum）；归档: $NAME.tar.gz（附 .sha256）
- **数据库**: 全部通过 PRAGMA integrity_check

## 恢复说明（谨慎操作）

\`\`\`bash
systemctl --user stop openclaw-gateway
cp -a config/openclaw.json ~/.openclaw/openclaw.json
cp -a data/zettelkasten/* ~/.openclaw/zettelkasten/
cp -a data/openupsp/* ~/.openclaw/openupsp/
cp -a data/svm/* ~/.openclaw/svm/
cp -a skills/* ~/.openclaw/skills/
cp -a plugin/zettelkasten-plugin/* ~/.openclaw/zettelkasten-plugin/
systemctl --user daemon-reload && systemctl --user start openclaw-gateway
\`\`\`

> 注意：恢复前务必先停止 Gateway，不要直接替换正在运行的 SQLite 文件。
EOF

echo "==> 打归档 $NAME.tar.gz"
tar -czf "$BACKUP_ROOT/$NAME.tar.gz" -C "$BACKUP_ROOT" "$NAME"
(cd "$BACKUP_ROOT" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
echo "✅ 归档: $BACKUP_ROOT/$NAME.tar.gz（$(du -sh "$BACKUP_ROOT/$NAME.tar.gz" | cut -f1)）"

echo "==> 清理旧备份（保留最近 $KEEP_FULL 次）"
mapfile -t old < <(ls -1d "$BACKUP_ROOT"/agent-stack-full-2*/ 2>/dev/null | sort -r | tail -n +"$((KEEP_FULL + 1))")
for d in "${old[@]}"; do
  base="$(basename "$d")"
  rm -rf "$d" "$BACKUP_ROOT/$base.tar.gz" "$BACKUP_ROOT/$base.tar.gz.sha256"
  echo "🗑️  已删除旧备份: $base"
done

echo
echo "✅ 备份完成: $DEST（$dir_size，$file_count 个文件）"
