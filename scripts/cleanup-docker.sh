#!/usr/bin/env bash
# cleanup-docker.sh — Docker 环境清理
#
# 用法:
#   scripts/cleanup-docker.sh              # 安全清理：已停止容器 + dangling 镜像 + 未使用网络 + 构建缓存
#   scripts/cleanup-docker.sh --all        # 追加：删除所有未被容器使用的镜像（image prune -a，含未打标签的旧版本）
#   scripts/cleanup-docker.sh --volumes    # 追加：删除未被容器使用的卷（⚠️ 可能丢数据，默认不启用）
#   scripts/cleanup-docker.sh --dry-run    # 只打印将执行的命令，不实际清理
#
# 说明:
#   - 默认模式不会动运行中的容器、被使用的镜像和卷，可放心跑。
#   - 每次执行前后各打印一次 docker system df，便于确认释放了多少空间。

set -euo pipefail

PRUNE_ALL=0
PRUNE_VOLUMES=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --all) PRUNE_ALL=1 ;;
    --volumes) PRUNE_VOLUMES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数: $arg（支持 --all / --volumes / --dry-run / --help）" >&2
      exit 2
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "⚠️  未安装 docker，无需清理，退出。"
  exit 0
fi
if ! docker info >/dev/null 2>&1; then
  echo "❌ docker daemon 不可用（无权限或未运行），中止。" >&2
  exit 1
fi

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    echo "==> $*"
    "$@"
  fi
}

echo "==> 清理前占用:"
docker system df

run docker container prune -f
run docker image prune -f
run docker network prune -f
run docker builder prune -f

if [[ "$PRUNE_ALL" -eq 1 ]]; then
  run docker image prune -a -f
fi

if [[ "$PRUNE_VOLUMES" -eq 1 ]]; then
  echo "⚠️  --volumes：将删除所有未被容器使用的卷"
  run docker volume prune -f
fi

echo
echo "==> 清理后占用:"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] 未实际清理，占用不变。"
else
  docker system df
  echo "✅ Docker 清理完成。"
fi
