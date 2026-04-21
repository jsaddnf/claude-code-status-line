#!/bin/bash
input=$(cat)

# 模型名
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# 剩余 context 百分比（Claude Code 传入，已算好）
REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100' | cut -d. -f1)

# 当前 git 分支
BRANCH=""
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "."')
if cd "$CWD" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
fi

# Effort 级别（low / medium / high / xhigh / max）
# Claude Code 不会通过 stdin 传 effort，所以按优先级从几处来源取：
#   1) 环境变量 CLAUDE_CODE_EFFORT_LEVEL（最高优先级）
#   2) 项目级 .claude/settings.json 的 effortLevel
#   3) 用户级 ~/.claude/settings.json 的 effortLevel
# 注意：/effort max 是会话级、不写入 settings.json，这里读不到，会显示 auto
EFFORT=""
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
    EFFORT="$CLAUDE_CODE_EFFORT_LEVEL"
elif [ -f "$CWD/.claude/settings.json" ]; then
    EFFORT=$(jq -r '.effortLevel // empty' "$CWD/.claude/settings.json" 2>/dev/null)
fi
if [ -z "$EFFORT" ] && [ -f "$HOME/.claude/settings.json" ]; then
    EFFORT=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
[ -z "$EFFORT" ] && EFFORT="auto"

# 颜色：剩余 >50% 绿色，20-50% 黄色，<20% 红色
if [ "$REMAINING" -gt 50 ]; then
    COLOR='\033[32m'
elif [ "$REMAINING" -gt 20 ]; then
    COLOR='\033[33m'
else
    COLOR='\033[31m'
fi
CYAN='\033[36m'
DIM='\033[2m'
RESET='\033[0m'

# Effort 颜色：低=灰，中=黄，高=青，xhigh=品红，max=红加粗
case "$EFFORT" in
    low)    EFFORT_COLOR='\033[2m' ;;
    medium) EFFORT_COLOR='\033[33m' ;;
    high)   EFFORT_COLOR='\033[36m' ;;
    xhigh)  EFFORT_COLOR='\033[35m' ;;
    max)    EFFORT_COLOR='\033[1;31m' ;;
    *)      EFFORT_COLOR='\033[2m' ;;
esac

EFFORT_SEG="⚡ ${EFFORT_COLOR}${EFFORT}${RESET}"

if [ -n "$BRANCH" ]; then
    echo -e "${DIM}[$MODEL]${RESET} 🌿 ${CYAN}${BRANCH}${RESET} │ 🧠 ${COLOR}${REMAINING}% context left${RESET} │ ${EFFORT_SEG}"
else
    echo -e "${DIM}[$MODEL]${RESET} 🧠 ${COLOR}${REMAINING}% context left${RESET} │ ${EFFORT_SEG}"
fi
