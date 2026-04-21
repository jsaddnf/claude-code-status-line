# Claude Code Status Line

一个极简的 [Claude Code](https://claude.com/claude-code) 自定义状态栏脚本，在底部实时显示：

- 🤖 当前模型名（如 `Opus 4.6`）
- 🌿 当前 Git 分支（如果工作目录在 Git 仓库中）
- 🧠 剩余 context 百分比（按阈值自动变色：>50% 绿、20–50% 黄、<20% 红）
- ⚡ 当前 effort 级别（`low` / `medium` / `high` / `xhigh` / `max`，按级别着色）

效果类似：

```
[Opus 4.6] 🌿 main │ 🧠 78% context left │ ⚡ xhigh
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

## 自定义

`statusline.sh` 非常简短，直接改即可：

- **颜色阈值**：修改 `REMAINING` 的判断分支
- **Effort 颜色**：修改 `case "$EFFORT" in ... esac` 分支
- **展示内容**：Claude Code 传入的 JSON 中还包含 `workspace`、`session`、`cost` 等字段，可按需 `jq` 取用
- **图标 / 格式**：直接改最后 `echo -e` 的模板

## 工作原理

Claude Code 会通过 stdin 向 `statusLine.command` 传入一段 JSON（包含模型、context 窗口、工作目录等信息），脚本的 stdout 就是状态栏内容，支持 ANSI 颜色转义。Effort 级别不在 stdin 中，由脚本自行从 `settings.json` / 环境变量读取。

## License

MIT
