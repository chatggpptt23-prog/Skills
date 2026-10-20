#!/usr/bin/env bash
# Install wq-workflow into a DeepSeek Harness skill root.
#
# Usage:
#   ./install.sh              # -> ${DSH_HOME:-$HOME/.dsh}/skills
#   ./install.sh --project    # -> ./.dsh/skills
#   ./install.sh --agents     # -> ~/.agents/skills (shared with Codex)
#   ./install.sh --dest DIR
#   ./install.sh --force

set -euo pipefail

PROJECT=0
AGENTS=0
DEST=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT=1; shift ;;
    --agents)  AGENTS=1; shift ;;
    --dest)    DEST="${2:?--dest 需要一个目录}"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/skills/wq-workflow"

[ -f "$SOURCE/SKILL.md" ] || { echo "找不到技能源目录: $SOURCE" >&2; exit 1; }

if [ -n "$DEST" ]; then
  ROOT="$DEST"
elif [ "$PROJECT" -eq 1 ]; then
  ROOT="$PWD/.dsh/skills"
elif [ "$AGENTS" -eq 1 ]; then
  ROOT="$HOME/.agents/skills"
else
  ROOT="${DSH_HOME:-$HOME/.dsh}/skills"
fi

TARGET="$ROOT/wq-workflow"

echo "源目录  : $SOURCE"
echo "目标目录: $TARGET"

# 同名副本提示
for r in "$HOME/.dsh/skills" "$HOME/.agents/skills" "$PWD/.dsh/skills" "$PWD/.agents/skills"; do
  [ "$r" = "$ROOT" ] && continue
  if [ -d "$r/wq-workflow" ]; then
    echo "警告: 其他可发现根中存在同名技能 -> $r/wq-workflow" >&2
    echo "警告: DSH 会按 rank 取其一，建议只保留一份。" >&2
  fi
done

if [ -d "$TARGET" ]; then
  if [ "$FORCE" -ne 1 ]; then
    echo
    echo "目标已存在，未做修改: $TARGET"
    echo "如需覆盖请加 --force；如需保留自定义修改，请先备份。"
    exit 1
  fi
  echo "移除旧副本: $TARGET"
  rm -rf "$TARGET"
fi

mkdir -p "$ROOT"
cp -R "$SOURCE" "$TARGET"

[ -f "$TARGET/SKILL.md" ] || { echo "安装后缺少 SKILL.md" >&2; exit 1; }

echo
echo "已安装: $TARGET"
find "$TARGET" -type f -printf '  %P  (%s bytes)\n' 2>/dev/null || ls -lR "$TARGET"

echo
echo "下一步：在 DSH 会话里用 /wq-workflow 调用，或直接描述开发任务让它按描述自动匹配。"
echo "DSH 会监视技能根目录，通常无需重启；若未出现在 / 菜单中，重开一个会话。"
