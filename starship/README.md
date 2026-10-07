# Starship 提示符

这份配置采用 Catppuccin Mocha 配色、Nerd Font 图标、Powerline 语义和双行布局，
把提示符拆成更容易维护的模块（视觉语言沿自早期的 Powerlevel10k 主题）。

## 设计决策

| 目标 | 实现 |
| --- | --- |
| 保持个人主题 | Catppuccin Mocha 调色板集中定义为 `catppuccin_mocha` palette（在 `starship.toml` 的 `[palettes.catppuccin_mocha]`） |
| 维持双行、留白和简洁感 | 第一行显示目录/Git/状态与运行时信息，第二行只放输入符号 |
| 快速判断仓库状态 | 分支、未跟踪、修改、暂存、冲突、领先/落后数量直接显示 |
| 减少噪声 | 语言版本只在对应项目中出现；命令耗时只显示超过 2 秒的命令 |
| 适配日常开发 | Python 虚拟环境、Node/Rust/Go 版本、后台任务和远程 SSH 上下文可见 |
| 控制启动开销 | `scan_timeout = 500`、`command_timeout = 1000`，避免提示符长时间阻塞命令行 |

配置文件位于 [`starship.toml`](starship.toml)，安装脚本会把它链接到
`${XDG_CONFIG_HOME:-~/.config}/starship.toml`。

## 启用方式

1. 确认命令可用：

   ```sh
   starship --version
   ```

2. 重新运行仓库安装脚本（会备份已有目标文件）：

   ```sh
   ./install.sh
   ```

3. 重新载入 fish：

   ```sh
   exec fish
   ```

`fish/config.fish` 会在检测到 `starship` 时初始化 Starship；如果 Starship
暂时不可用，则继续使用 Fish 的默认提示符，避免远程或救援环境无法使用
shell。

## 校验与调试

```sh
# 输出合并后的有效配置（用于确认 Starship 能解析 TOML）
starship print-config > /tmp/starship-effective.toml

# 查看某个目录下最终渲染的提示符
STARSHIP_LOG=error starship module directory
STARSHIP_LOG=error starship module git_status

# 仅在需要时临时切换配置
STARSHIP_CONFIG=/path/to/another/starship.toml exec fish
```

若 Nerd Font 图标显示为方框，请确认终端正在使用 FiraCode Nerd Font Mono，
并重启终端使字体设置生效。

## 后续微调

- 想要更紧凑：把 `add_newline` 改为 `false`，或移除 `$time`。
- 想要更多 Git 细节：在 `[git_status]` 中增加状态符号或调整各状态计数。
- 想要在所有目录显示语言版本：为相应模块设置 `detect_extensions = []` 和
  `detect_files = []`，但这会增加提示符信息量和扫描次数。
