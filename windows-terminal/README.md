# Windows Terminal

Windows Terminal 配置（`settings.json`）。配色、主题与仓库其余部分保持一致：
Catppuccin Mocha 配色 + Catppuccin Mocha 主题（深色标签栏/窗口），字体使用
JetBrains Maple Mono Light。

与 Neovim / tmux / Fish 不同，Windows Terminal 从 **Windows 侧**读取它的
`settings.json`，WSL 里的符号链接不会被 Windows 进程当作同一个文件解析，
因此 `install.sh` 在 WSL 下用 **复制** 而不是链接来部署该文件。

## 部署目标

`install.sh` 只在检测到 WSL（存在 `cmd.exe`）时部署，目标路径为：

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

部署前会先把现有文件改名为带时间戳的备份（`settings.json.backup-YYYYMMDD-HHMMSS`），
再复制仓库版本过去。请先关闭 Windows Terminal 再部署，否则终端可能在你复制
之后把内存中的设置写回，覆盖掉新文件；部署后重启 Windows Terminal 生效。

## 设计决策

| 目标 | 实现 |
| --- | --- |
| 与仓库统一配色 | `schemes[].name = "Catppuccin Mocha"`，`profiles.defaults.colorScheme` 指向它 |
| 深色窗口主题 | 顶层 `theme = "Catppuccin Mocha"`，`themes[]` 定义标签栏/窗口深色背景 |
| 统一默认字体 | `profiles.defaults.font` 设为 JetBrains Maple Mono Light |
| 复制时去掉富文本格式 | `copyFormatting = "none"` |
| 手动复制（选中后按键复制） | `copyOnSelect = false`，复制走 Windows Terminal 默认的 `Ctrl+Shift+C` |
| 自动方向复制分屏 | `alt+shift+d` → `Terminal.DuplicatePaneAuto` |

### Review 时做的修改

保存到仓库时相对原配置做了两处清理：

1. **移除 `ctrl+c → CopyToClipboard` 绑定。** 把 `Ctrl+C` 显式绑定为复制会让
   `Ctrl+C` 不再传给 shell，PowerShell 和 WSL 里就无法用它中断正在运行的
   命令。复制改用 Windows Terminal 默认的 `Ctrl+Shift+C` 即可。若确实想要
   “选中后 `Ctrl+C` 复制”，更好的办法是把 `copyOnSelect` 改为 `true`（选中即
   自动复制），这样 `Ctrl+C` 仍然保留为中断信号。

2. **删除未使用的 Solarized 配置。** 原配置里有 `Solarized Dark (modified)`
   配色和 `Solarized Dark` 主题，但没有 profile 引用它们，属于死配置，已移除。

## 机器相关字段（换机器时需要留意）

这份配置里有几个值绑定了当前机器，换机器后不会直接可用：

- **WSL Ubuntu profile 不再手写维护。** 之前的 `guid`、`--distribution-id
  {d0e8955a-...}` 和 `icon`（`C:\Users\max_h\...`）都绑定了当前机器，换机器后
  会失效。现已删掉这个 profile，交给 WSL 动态生成器：每台机器上 WSL 会自动
  创建带正确 GUID 和默认图标的 Ubuntu-26.04 profile，`profiles.defaults` 里的
  配色/字体/透明度仍然生效。
- **Nvidia_SDKM / Azure Cloud Shell** 等 `source` 为动态生成的 profile 会自动
  出现，即使设为 `hidden` 也可能在别处重新生成，无需在仓库里维护。

`defaultProfile` 目前指向 PowerShell Core（`{574e775e-...}`）。如果想默认打开
WSL Ubuntu，因为 WSL 自动生成的 profile GUID 每台机器不同，需要在本机 Windows
侧把 `defaultProfile` 改成自动生成的那个 Ubuntu GUID（或用片段扩展覆盖），
不要写死在仓库里。

## 校验

在 Windows 侧打开 Windows Terminal：

```powershell
# 打开设置文件确认已生效（会以默认编辑器打开当前生效的 settings.json）
wt --help
```

WSL 侧确认部署到的文件与仓库一致：

```sh
diff /mnt/c/Users/max_h/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json \
     windows-terminal/settings.json
```

确认配色/主题/字体生效：新标签页应显示 Catppuccin Mocha 深色主题，字体为
JetBrains Maple Mono Light；`Ctrl+C` 应能在 shell 里中断运行中的命令。
