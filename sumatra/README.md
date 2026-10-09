# SumatraPDF

SumatraPDF 配置（`SumatraPDF-settings.txt`）。配色与仓库其余部分保持一致：
内置主题 `Mocha` 使用 Catppuccin Mocha 的四个颜色（文字 `#cdd6f4`、主背景
`#1e1e2e`、控件背景 `#181825`、链接 `#89b4fa`），只给窗口 / 工具栏 / 侧栏 /
标签着色（`ColorizeControls = true`），**PDF 页面本身仍是白底黑字**
（`FixedPageUI` 的 `TextColor`/`BackgroundColor` 不变），保证图纸、规格书等
文档的可读性。

与 Neovim / tmux / Fish 不同，SumatraPDF 从 **Windows 侧**读取它的设置文件，
WSL 里的符号链接不会被 Windows 进程当作同一个文件解析，因此 `install.sh`
在 WSL 下用 **复制** 而不是链接来部署该文件。

## 部署目标

`install.sh` 只在检测到 WSL（存在 `cmd.exe`）时部署。SumatraPDF 3.5+ 把设置
放在 `%LOCALAPPDATA%\SumatraPDF\SumatraPDF-settings.txt`，旧版本放在
`%APPDATA%\SumatraPDF\SumatraPDF-settings.txt`；脚本会优先匹配 `LOCALAPPDATA`
（3.5+），找不到时回退到 `APPDATA`（旧版本）：

```
%LOCALAPPDATA%\SumatraPDF\SumatraPDF-settings.txt   （优先）
%APPDATA%\SumatraPDF\SumatraPDF-settings.txt        （回退）
```

部署前会先把现有文件改名为带时间戳的备份
（`SumatraPDF-settings.txt.backup-YYYYMMDD-HHMMSS`），再复制仓库版本过去。
请先关闭 SumatraPDF 再部署，否则运行中的实例可能在复制之后把内存中的设置
写回，覆盖掉新文件；部署后重启 SumatraPDF 生效。

## 设计决策

| 目标 | 实现 |
| --- | --- |
| 与仓库统一配色 | `Themes[].Name = "Mocha"`，`Theme = Mocha`，颜色取 Catppuccin Mocha |
| 只给 UI 着色、不动页面 | `ColorizeControls = true`，`FixedPageUI` 保持白底黑字 |
| 默认打开目录面板 | `ShowToc = true`（侧栏默认显示文档目录） |
| 标签页浏览 | `UseTabs = true`，`TabWidth = 300` |
| 记住阅读位置 | `RememberOpenedFiles` / `RememberStatePerDocument` / `RestoreSession` 均为 `true` |
| 中文界面 | `UiLanguage = cn` |

### Review 时做的清理

保存到仓库时相对本机 `%LOCALAPPDATA%\SumatraPDF\SumatraPDF-settings.txt` 做了
清理，删掉了绑定当前机器和运行时状态的部分：

1. **删除窗口几何信息。** `WindowState`、`WindowPos`（主窗口和每个文档各一份）
   绑定当前显示器和窗口布局，换机器后会失效，已移除，交给 SumatraPDF 运行时
   重新记录。
2. **删除文件历史与恢复会话。** `FileStates [...]` 记录的是本机打开过的具体
   文档路径（含 `C:\Users\max_h\...`、`E:\01-project\...` 等），`SessionData [...]`
   是上次退出时的标签页布局，都属于私有状态，已移除。
3. **删除运行时统计。** `TimeOfLastUpdateCheck`、`OpenCountWeek` 是程序自己
   维护的计数，已移除；文件末尾 `# Settings below are not recognized by the
   current version` 之后的内容是旧版本遗留，已一并移除。

## 机器相关字段（换机器时需要留意）

- **`UiLanguage = cn`** 是界面语言偏好（简体中文）。如果想用英文界面，把这一
  行改成 `UiLanguage = en` 或直接删掉。
- 其余设置均为跨机器可用的偏好，没有绑定具体路径或 GUID。

## 校验

SumatraPDF 会在退出时按自己的规范重写设置文件（重排序、给空值补空格等），
所以部署后与仓库的 `diff` 不会逐字节一致，这是正常现象。校验时比对关键项：

```sh
grep -E 'Theme = Mocha|ColorizeControls|UiLanguage' \
  /mnt/c/Users/max_h/AppData/Local/SumatraPDF/SumatraPDF-settings.txt
```

在 Windows 侧打开 SumatraPDF 确认：窗口 / 工具栏 / 侧栏为 Catppuccin Mocha
深色，PDF 页面仍为白底黑字，界面语言为中文。
