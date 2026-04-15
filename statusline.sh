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

if [ -n "$BRANCH" ]; then
    echo -e "${DIM}[$MODEL]${RESET} 🌿 ${CYAN}${BRANCH}${RESET} │ 🧠 ${COLOR}${REMAINING}% context left${RESET}"
else
    echo -e "${DIM}[$MODEL]${RESET} 🧠 ${COLOR}${REMAINING}% context left${RESET}"
fi
