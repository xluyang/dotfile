# Tmux and TPM

This directory contains the standalone tmux configuration used by this dotfile.
`tmux.conf` owns tmux options, personal key bindings, plugin declarations, and
the status bar. `colors.conf` contains the Catppuccin Mocha palette referenced
by the status bar and pane/window styles.

The status bar layout and palette direction are adapted from
[`naivecynics/primary-tmux`](https://github.com/naivecynics/primary-tmux); the
base tmux behavior and bindings are personal settings.

The bar is positioned at the top. Its left side shows the session, active
command, working directory, and zoom state; window entries use Nerd Font
icons for common shells and tools; the right side shows memory, CPU, and
battery information supplied by TPM plugins.

## Installation

From the repository root, run `./install.sh`. The installer clones the Tmux
Plugin Manager (TPM) into `$XDG_CONFIG_HOME/tmux/plugins` by default. Set
`TMUX_PLUGIN_MANAGER_PATH` before installation to choose a different location.

Requirements are tmux, Git, and Bash. Nerd Font glyphs are recommended for the
status bar icons.

## Plugins

`tmux/tmux.conf` enables `tmux-plugins/tmux-sensible` and initializes TPM at
the end of the file. Add plugins with the same syntax:

```tmux
set -g @plugin 'owner/repository'
```

Reload the configuration with `tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"`,
then use the following prefix bindings (this configuration uses `Ctrl-a`):

- `prefix + I` installs newly declared plugins.
- `prefix + u` updates TPM and all plugins.
- `prefix + Alt-u` removes plugins no longer in the configuration.

The installer links both configuration files into
`$XDG_CONFIG_HOME/tmux` (default: `~/.config/tmux`). Set
`TMUX_PLUGIN_MANAGER_PATH` before running `./install.sh` to place TPM and its
plugins elsewhere.

To remove the session state saved by `tmux-resurrect`, delete its latest
snapshot:

```bash
rm -f ~/.tmux/resurrect/last
```

## Key bindings

The prefix is `Ctrl-a`. After the prefix, `-` splits vertically (stacked) and
`v` (or `Shift+-`) splits horizontally (side by side); `h`, `j`, `k`, and `l`
navigate panes, while `H`, `J`, `K`, and `L` resize the active pane. `r` reloads
the linked `tmux.conf`.

## Clipboard (copy and paste)

tmux-yank copies the selection to the system clipboard. On WSL its default
(`cat | clip.exe`) reads bytes as the Windows console codepage; on a zh-CN
Windows that codepage is GBK (cp936), so UTF-8 Chinese text gets mangled. The
config therefore prefers `win32yank.exe`, a UTF-8-native clipboard tool, when
it is available and only falls back to `clip.exe`.

`win32yank.exe` ships with the Windows build of Neovim (this repository pairs
with Neovim) or can be installed with `winget install win32yank` / scoop. Put
it somewhere on the Windows `PATH` so WSL can resolve `win32yank.exe`.

The config also enables tmux's built-in `set-clipboard`, so selecting text in
copy mode sends an OSC 52 escape to set the terminal clipboard directly
(UTF-8-safe). Windows Terminal, iTerm2, kitty, and WezTerm all support OSC 52;
in terminals without support the escape is ignored and tmux-yank's copy
command is still available via `Ctrl-a y`.

## Pane Zoom and Historical Maximize Behavior

This configuration uses tmux's built-in pane zoom: `Ctrl-a z` runs
`resize-pane -Z`, so the active pane fills its current window and the same
shortcut restores the previous layout. `Ctrl-a +` is intentionally unbound.

For reference, oh-my-tmux used `prefix +` for a different operation. It moved
the active pane into a separate window and used the same shortcut to restore it
to the source window. Unlike `resize-pane -Z`, that approach allowed further
splitting inside the maximized window and preserved the maximized pane while
switching between windows. That historical behavior is documented here only;
it is not a dependency of this standalone configuration.
