# dotfiles

Personal Linux/WSL development-environment configuration for Neovim, tmux,
Fish (with Starship), Windows Terminal, and SumatraPDF.

![最终配置展示](assets/showcase.png)

## Architecture

This repository uses explicit configuration files and manual symbolic links.
`install.sh` is the deployment entry point; it does not use GNU Stow or
chezmoi, and it does not change the login shell.

| Area | Repository entry point | Deployment target | Managed by `install.sh` |
| --- | --- | --- | --- |
| Neovim | `nvim/` | `${XDG_CONFIG_HOME:-~/.config}/nvim` | Yes, directory link |
| tmux | `tmux/tmux.conf` | `${XDG_CONFIG_HOME:-~/.config}/tmux/tmux.conf` | Yes |
| tmux palette | `tmux/colors.conf` | `${XDG_CONFIG_HOME:-~/.config}/tmux/colors.conf` | Yes |
| Fish | `fish/config.fish`, `fish/conf.d/` | `${XDG_CONFIG_HOME:-~/.config}/fish/` | Yes, per-file links |
| Fisher manifest | `fish/fish_plugins` | `${XDG_CONFIG_HOME:-~/.config}/fish/fish_plugins` | Yes |
| Starship | `starship/starship.toml` | `${XDG_CONFIG_HOME:-~/.config}/starship.toml` | Yes |
| Windows Terminal | `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Yes, file copy (WSL only) |
| SumatraPDF | `sumatra/SumatraPDF-settings.txt` | `%LOCALAPPDATA%\SumatraPDF\SumatraPDF-settings.txt` (fallback `%APPDATA%`) | Yes, file copy (WSL only) |

## Shell model

Fish is the interactive shell, with Starship as the prompt. Scripts keep their
own shebang (`#!/usr/bin/env bash`); no configuration in this repository calls
`chsh`, so switching the login shell is optional and left to you.

## Prerequisites

The installer assumes `sh`, `git`, and a writable home directory. It installs
TPM but does not install system packages, Neovim, tmux, Fish, Nerd Fonts,
Starship, or command-line tools. To install the toolchain automatically on a
fresh machine, use `./bootstrap.sh` (see [Bootstrap](#bootstrap-one-shot-setup)).

On Ubuntu/WSL, install a practical baseline with:

```sh
sudo apt update
sudo apt install -y git curl tmux fish fzf ripgrep fd-find
```

Install shell-specific managers and themes as described in:

- [Fish, Fisher, and Starship](fish/README.md)
- [Starship prompt](starship/README.md)
- [Tmux and TPM](tmux/README.md)
- [Neovim/LazyVim](nvim/README.md)
- [Windows Terminal](windows-terminal/README.md)
- [SumatraPDF](sumatra/README.md)

## Deployment

For a full one-shot setup (packages + managers + dotfiles), use
`./bootstrap.sh` instead — see [Bootstrap](#bootstrap-one-shot-setup) below.
To deploy only the dotfiles, clone the repository and run the installer:

```sh
git clone <your-repository-url> ~/Document/dotfile
cd ~/Document/dotfile
./install.sh
```

The installer detects the operating system (`uname -s` plus WSL markers) and
adapts: on Linux and macOS it only creates symlinks; under WSL it additionally
copies the Windows-side configs (Windows Terminal, SumatraPDF). Native Windows
is not supported — on Windows, install WSL and run the installer from inside
WSL; the script refuses to run in other environments (e.g. a native Windows
shell).

Existing target files are moved to timestamped sibling backups before a link
is created. Fish is handled per file so Fisher-generated functions,
completions, plugin `conf.d` files, and `fish_variables` remain untouched.

TPM defaults to `${XDG_CONFIG_HOME:-~/.config}/tmux/plugins`. Override its
location before deployment when required:

```sh
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" ./install.sh
```

Under WSL, the installer also copies `windows-terminal/settings.json` to the
Windows Terminal `LocalState` directory. It cannot be a symlink across the
WSL/Windows boundary, so the file is copied instead. Close Windows Terminal
before deploying so the running instance does not overwrite the copied file.
The same applies to `sumatra/SumatraPDF-settings.txt`, copied to SumatraPDF's
settings directory (3.5+ under `%LOCALAPPDATA%`, older under `%APPDATA%`);
close SumatraPDF before deploying for the same reason.

The installer does not install Fisher plugins. After installing Fish and
Fisher, synchronize the repository manifest with:

```sh
fish -c 'fisher update'
```

## Bootstrap (one-shot setup)

`bootstrap.sh` is the "new machine" entry point. It runs every numbered step
in `setup/` in order and stops on the first failure. Each step is idempotent,
so re-running the whole script is safe.

```sh
./bootstrap.sh
```

Steps live in `setup/`:

| Step | Responsibility |
| --- | --- |
| `00_system.sh` | Base packages (fish, git, curl, tmux, fzf, ripgrep, fd, jq, ...) |
| `05_docker.sh` | Docker Engine + CLI + Compose (adds user to the docker group) |
| `10_neovim.sh` | Install latest Neovim from the official GitHub release |
| `15_cli_tools.sh` | Install eza, lazygit, and yazi (used by fish aliases) |
| `20_deploy.sh` | Symlink dotfiles and install TPM (runs `install.sh`) |
| `30_fisher.sh` | Install Fisher and sync `fish_plugins` |
| `40_node.sh` | Install Node.js LTS and set `nvm_default_version` |
| `50_starship.sh` | Install the Starship binary |

Adding a tool is just a new numbered file in `setup/`; `bootstrap.sh` discovers
and runs it automatically. Numbering encodes order: steps numbered below `20`
run before deployment, `20` deploys, and steps above `20` run after.

Planned-but-not-yet-needed steps are tracked in [TODO.md](TODO.md).

### Troubleshooting

- **`apt-get update` fails on a new Ubuntu release** (for example, a stale
  `fish-shell` PPA returns 404 or an old `docker.list` errors out): remove the
  stale third-party sources, then re-run. Ubuntu ships Fish in its default
  repositories, so the Fish PPA is unnecessary:

  ```sh
  ls /etc/apt/sources.list.d/
  sudo rm -f /etc/apt/sources.list.d/*fish* /etc/apt/sources.list.d/docker.list
  sudo apt-get update
  ```

- **China networks** (`download.docker.com` / `nodejs.org` / Docker Hub
  unreachable): the Docker and Node steps probe the official hosts and fall
  back to USTC / npmmirror automatically, and Docker image pulls fall back to
  a working public registry mirror, so plain `./bootstrap.sh` works. Public
  registry mirrors change often; for a reliable one, use a free Aliyun
  accelerator and force it (or any mirror) with:

  ```sh
  DOCKER_APT_MIRROR=https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
  NVM_MIRROR=https://npmmirror.com/mirrors/node \
  DOCKER_REGISTRY_MIRRORS=https://<your-id>.mirror.aliyuncs.com \
  ./bootstrap.sh
  ```

## Component summary

### Neovim

LazyVim is the base distribution managed by `lazy.nvim`. Personal plugin
specifications live in `nvim/lua/plugins/`; Catppuccin Mocha, bufferline,
Noice/Snacks, and the custom lualine statusline are configured there. See the
[Neovim README](nvim/README.md) and the [development guide](nvim/lazyvim-development-guide.md).

### tmux

The standalone `tmux/tmux.conf` owns options, `Ctrl-a` bindings, plugin
declarations, status-bar layout, and pane/window styles. `colors.conf` provides
the Catppuccin Mocha palette. TPM is initialized at the end of the file; the
oh-my-tmux dependency and `tmux.conf.local` have been removed. See
[tmux/README.md](tmux/README.md) for plugin controls and pane zoom behavior.

### Fish

Fish uses Fisher with a manifest containing `z`, `fzf.fish`, `done`, `bass`, and
`nvm.fish`. Configuration is split into `config.fish` (Starship prompt init) and
numbered `conf.d/` modules; the Docker SDK helpers (`denter` + `bst_sdk_*`),
WSL proxy functions, AI environment variables, and private `fish.local` loading
live there. See [fish/README.md](fish/README.md).

### Starship

Starship is the prompt for Fish, with a Catppuccin Mocha two-line theme. See
[starship/README.md](starship/README.md).

### Windows Terminal

`windows-terminal/settings.json` carries the Windows Terminal profiles, the
Catppuccin Mocha color scheme and dark window theme, and the JetBrains Maple
Mono font. Unlike the other components it is copied (not symlinked) to the
Windows-side `LocalState` path and is only deployed under WSL. See
[windows-terminal/README.md](windows-terminal/README.md).

### SumatraPDF

`sumatra/SumatraPDF-settings.txt` carries a Catppuccin Mocha UI theme
(`Mocha`) that colors the window, toolbar, sidebar, and tabs while keeping
PDF pages white-on-black-free (white page, black text). Like Windows Terminal
it is copied (not symlinked) to the Windows-side settings path and is only
deployed under WSL. See [sumatra/README.md](sumatra/README.md).

## Verification

After deployment, verify links and shell configuration:

```sh
git status --short
sh -n install.sh
sh -n bootstrap.sh
tmux -V
fish --version
fish -c 'fisher list'
starship --version
```

For an interactive check, run `fish`, start tmux, and confirm the Catppuccin
status bar and the Starship prompt render with the installed Nerd Font.

## Updating the repository

Edit repository files, rerun `./install.sh` when links need refreshing, and
commit only the component being changed:

```sh
git add nvim tmux fish starship windows-terminal sumatra README.md install.sh bootstrap.sh setup
git commit
```

Keep generated plugin directories, caches, `fish_variables`, and private
credential files outside Git. Review timestamped backups before removing any
old local configuration.
