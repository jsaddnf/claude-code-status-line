# Claude Code Status Line

一个极简的 [Claude Code](https://claude.com/claude-code) 自定义状态栏脚本，在底部实时显示：

- 🤖 当前模型名（如 `Opus 4.6`）
- 🌿 当前 Git 分支（如果工作目录在 Git 仓库中）
- 🧠 剩余 context 百分比（按阈值自动变色：>50% 绿、20–50% 黄、<20% 红）
- ⚡ 当前 effort 级别（`low` / `medium` / `high` / `xhigh` / `max`，按级别着色）
- 📊 5 小时滚动用量进度条（订阅套餐才有此字段；<60% 绿、60–85% 黄、≥85% 红）
- 💰 本会话累计花费（仅 API billing 模式显示；<$1 灰、<$10 青、<$50 黄、≥$50 红）

`📊` 和 `💰` 根据计费模式自动二选一：

```
订阅套餐:   [Opus 4.6] 🌿 main │ 🧠 78% context left │ ⚡ xhigh │ 📊 ▓▓▓░░░░░░░ 30% /5h
API billing: [Opus 4.6] 🌿 main │ 🧠 78% context left │ ⚡ xhigh │ 💰 $3.42
```

## 依赖

- `bash`
- `jq`（用于解析 Claude Code 传入的 JSON 状态）
- `git`（可选，没有分支信息时会自动省略）

macOS 安装 `jq`：

```bash
brew install jq
```

## 一键安装

```bash
git clone https://github.com/jsaddnf/claude-code-status-line.git
cd claude-code-status-line
bash install-statusline.sh
```

安装脚本会：

1. 将 `statusline.sh` 复制到 `~/.claude/statusline.sh` 并赋予可执行权限
2. 在 `~/.claude/settings.json` 中追加 `statusLine` 配置（已有配置会通过 `jq` 合并，保留原字段）

完成后**重启 Claude Code 窗口**即可看到状态栏。

## 手动安装

如果你想自己控制安装过程：

```bash
mkdir -p ~/.claude
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

然后在 `~/.claude/settings.json` 中加入：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 2
  }
}
```

## Effort 显示

Claude Code 的 status line stdin **不会**传入当前 effort 级别，所以脚本按下列优先级从配置中读取：

1. 环境变量 `CLAUDE_CODE_EFFORT_LEVEL`（最高优先级）
2. 项目级 `.claude/settings.json` 里的 `effortLevel`
3. 用户级 `~/.claude/settings.json` 里的 `effortLevel`
4. 都没有则显示 `auto`

颜色：`low` 灰、`medium` 黄、`high` 青、`xhigh` 品红、`max` 红加粗。

### 已知限制

会话内通过 `/effort max` 设置的值**不会**被捕获（max 是会话级，不写入 settings.json，stdin 里也没有），status line 会显示 `auto`。如果希望 `max` 也在状态栏可见，启动 Claude Code 前先：

```bash
export CLAUDE_CODE_EFFORT_LEVEL=max
```

## Rate limit 用量

从 stdin JSON 的 `rate_limits.five_hour.used_percentage` 字段读取 5 小时滚动限额已用百分比，用 10 段进度条呈现，颜色随用量变深。需要 7 天限额（`rate_limits.seven_day.used_percentage`）或两者同时显示，自行在 `statusline.sh` 里仿照这一段加一个 segment 即可。

> `rate_limits.*` 字段只在使用 Anthropic 订阅套餐（Pro / Max / Team / Enterprise）时由 Claude Code 填充。使用 API billing（按量付费、直接用 API key）时该字段通常不存在，脚本会自动隐藏这一段。

## Session 花费

仅对 **API billing** 用户显示，从 `cost.total_cost_usd` 字段读取本会话累计花费（USD），基于 token 消耗和当前价目表在客户端估算，与最终账单可能有小幅误差。

订阅套餐用户不显示 cost，因为订阅下的这个值只是"假如按 API 付费要花多少"的虚拟估算，与实际支出没关系，显示出来反而误导。判断逻辑是：`rate_limits` 字段有值则视为订阅模式，此时隐藏 cost 段。

API billing 用户要监控**月度账单**或**API tier 的 RPM/TPM 利用率**，只能去 [console.anthropic.com](https://console.anthropic.com) 后台看——那些数据 Claude Code 拿不到、status line 也没法显示。

## 自定义

`statusline.sh` 非常简短，直接改即可：

- **Context 颜色阈值**：修改 `REMAINING` 的判断分支
- **Effort 颜色**：修改 `case "$EFFORT" in ... esac` 分支
- **Usage 进度条段数 / 颜色阈值**：修改 `USED` 相关段落（目前 10 段、60/85 分档）
- **Cost 阈值**：修改 `COST_CENTS` 的判断分支（目前 $1 / $10 / $50 分档）
- **展示内容**：Claude Code 传入的 JSON 中还包含 `workspace`、`session` 等字段，可按需 `jq` 取用
- **图标 / 格式**：直接改最后 `echo -e` 的模板

## 工作原理

Claude Code 会通过 stdin 向 `statusLine.command` 传入一段 JSON（包含模型、context 窗口、工作目录等信息），脚本的 stdout 就是状态栏内容，支持 ANSI 颜色转义。Effort 级别不在 stdin 中，由脚本自行从 `settings.json` / 环境变量读取。

## License

MIT
