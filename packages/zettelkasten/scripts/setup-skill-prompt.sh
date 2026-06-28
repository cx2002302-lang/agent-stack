#!/bin/bash
#
# 设置 zettelkasten-brain Skill 的 systemPromptOverride（仅限 OpenClaw 2026.4.x）
# 如果 OpenClaw >= 2026.6，则跳过（SKILL.md 处理提示词注入）
#

set -e

# 检测 OpenClaw 版本
OC_VERSION=$(openclaw --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "0.0.0")
OC_MAJOR=$(echo "$OC_VERSION" | cut -d. -f1)
OC_MINOR=$(echo "$OC_VERSION" | cut -d. -f2)

if [ "$OC_MAJOR" -gt 2026 ] || { [ "$OC_MAJOR" -eq 2026 ] && [ "$OC_MINOR" -ge 6 ]; }; then
  echo "ℹ️  systemPromptOverride not supported in OpenClaw 2026.6+; SKILL.md handles prompt injection"
  echo "   Skipping systemPromptOverride setup."
  exit 0
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="${PROJECT_DIR}/skills/brain"
VERSION_FILE="${SKILL_DIR}/VERSION"
PROMPT_FILE="${SKILL_DIR}/PROMPT.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: PROMPT.md not found at $PROMPT_FILE" >&2
  exit 1
fi

# 从 VERSION 文件解析参数
VERSION=$(grep '^version:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
STAGE=$(grep '^stage:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
NEXT_EVOLUTION=$(grep '^next_evolution:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
SENSITIVITY=$(grep '^  sensitivity:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
SEARCH_DEPTH=$(grep '^  search_depth:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
LINK_THRESHOLD=$(grep '^  link_threshold:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
TAG_LIMIT=$(grep '^  tag_limit:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')
AUTO_ARCHIVE=$(grep '^  auto_archive:' "$VERSION_FILE" | awk -F': ' '{print $2}' | tr -d ' ')

# 读取并替换占位符
PROMPT=$(cat "$PROMPT_FILE" | sed \
  -e "s/{{VERSION}}/${VERSION}/g" \
  -e "s/{{DATE}}/$(date -u +%Y-%m-%d)/g" \
  -e "s/{{STAGE}}/${STAGE}/g" \
  -e "s/{{NEXT_EVOLUTION}}/${NEXT_EVOLUTION}/g" \
  -e "s/{{SENSITIVITY}}/${SENSITIVITY}/g" \
  -e "s/{{SEARCH_DEPTH}}/${SEARCH_DEPTH}/g" \
  -e "s/{{LINK_THRESHOLD}}/${LINK_THRESHOLD}/g" \
  -e "s/{{TAG_LIMIT}}/${TAG_LIMIT}/g" \
  -e "s/{{AUTO_ARCHIVE}}/${AUTO_ARCHIVE}/g")

# 确保 alsoAllow 包含 zettelkasten（不破坏现有配置）
openclaw config set tools.alsoAllow '["zettelkasten"]' 2>/dev/null || true

# 写入 systemPromptOverride
openclaw config set agents.defaults.systemPromptOverride "$PROMPT"

echo "✅ zettelkasten-brain systemPromptOverride set (version: ${VERSION})"
echo "   Next: openclaw gateway restart"
