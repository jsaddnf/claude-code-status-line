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

# 5 小时 rate limit 用量进度条（字段缺失时整段隐藏）
USAGE_SEG=""
USED_RAW=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$USED_RAW" ]; then
    USED=$(printf '%.0f' "$USED_RAW" 2>/dev/null || echo 0)
    # 颜色：<60% 绿、60-85% 黄、>=85% 红
    if   [ "$USED" -lt 60 ]; then USAGE_COLOR='\033[32m'
    elif [ "$USED" -lt 85 ]; then USAGE_COLOR='\033[33m'
    else                          USAGE_COLOR='\033[31m'
    fi
    # 10 段进度条，每段 10%
    FILLED=$(( (USED + 5) / 10 ))
    [ "$FILLED" -gt 10 ] && FILLED=10
    [ "$FILLED" -lt 0  ] && FILLED=0
    EMPTY=$(( 10 - FILLED ))
    BAR=""
    for _ in $(seq 1 "$FILLED"); do BAR="${BAR}▓"; done
    for _ in $(seq 1 "$EMPTY");  do BAR="${BAR}░"; done
    USAGE_SEG=" │ 📊 ${USAGE_COLOR}${BAR} ${USED}%${RESET} ${DIM}/5h${RESET}"
fi

# 本会话累计花费（仅在 API billing 模式下显示）
# 订阅套餐的 cost.total_cost_usd 是按 API 估算的虚拟值、不是实际支出，显示出来会误导。
# 判断依据：rate_limits 字段只在订阅套餐下填充，USED_RAW 非空即订阅模式，此时隐藏 cost。
COST_SEG=""
if [ -z "$USED_RAW" ]; then
    COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
    if [ -n "$COST_RAW" ]; then
        # 转成整数分用于阈值比较（bash 不支持浮点比较）
        COST_CENTS=$(awk -v c="$COST_RAW" 'BEGIN{printf "%d", c*100}')
        # <$1 灰 / <$10 青 / <$50 黄 / >=$50 红
        if   [ "$COST_CENTS" -lt 100 ]; then  COST_COLOR='\033[2m'
        elif [ "$COST_CENTS" -lt 1000 ]; then COST_COLOR='\033[36m'
        elif [ "$COST_CENTS" -lt 5000 ]; then COST_COLOR='\033[33m'
        else                                  COST_COLOR='\033[31m'
        fi
        COST_FMT=$(printf '%.2f' "$COST_RAW")
        COST_SEG=" │ 💰 ${COST_COLOR}\$${COST_FMT}${RESET}"
    fi
fi

if [ -n "$BRANCH" ]; then
    echo -e "${DIM}[$MODEL]${RESET} 🌿 ${CYAN}${BRANCH}${RESET} │ 🧠 ${COLOR}${REMAINING}% context left${RESET} │ ${EFFORT_SEG}${USAGE_SEG}${COST_SEG}"
else
    echo -e "${DIM}[$MODEL]${RESET} 🧠 ${COLOR}${REMAINING}% context left${RESET} │ ${EFFORT_SEG}${USAGE_SEG}${COST_SEG}"
fi
