#!/bin/bash
# 一键安装 Claude Code 状态栏
set -e

mkdir -p ~/.claude

# 1) 复制 statusline 脚本
cp "$(dirname "$0")/statusline.sh" ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# 2) 合并 settings.json（若已存在则用 jq 合并，保留原有字段）
SETTINGS=~/.claude/settings.json
NEW_CFG='{"statusLine":{"type":"command","command":"~/.claude/statusline.sh","padding":2}}'

if [ -f "$SETTINGS" ]; then
  tmp=$(mktemp)
  jq ". + $NEW_CFG" "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  echo "$NEW_CFG" | jq . > "$SETTINGS"
fi

echo "✅ 安装完成。重启 Claude Code 窗口即可看到状态栏。"
echo "   脚本:  ~/.claude/statusline.sh"
echo "   配置:  ~/.claude/settings.json"
