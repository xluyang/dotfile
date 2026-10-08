#!/bin/sh
# Portable installer: POSIX sh only. No GNU `--` flags and no `readlink -f`,
# so the same script runs unchanged on Linux and other Unix-like systems.
set -eu

repo_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}
tmux_plugin_dir=${TMUX_PLUGIN_MANAGER_PATH:-"$config_dir/tmux/plugins"}
timestamp=$(date +%Y%m%d-%H%M%S)

backup_target() {
  target=$1
  backup="${target}.backup-${timestamp}"

  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${backup}-1"
  done

  mv "$target" "$backup"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

link_config() {
  source_path=$1
  target_path=$2

  mkdir -p "$(dirname "$target_path")"

  # The link stores source_path verbatim (it is always absolute here), so
  # comparing the raw link target is enough and avoids GNU `readlink -f`.
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    printf 'Already linked: %s\n' "$target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_target "$target_path"
  fi

  ln -s "$source_path" "$target_path"
  printf 'Linked %s -> %s\n' "$target_path" "$source_path"
}

install_tpm() {
  tpm_dir="$tmux_plugin_dir/tpm"

  if [ -d "$tpm_dir/.git" ]; then
    printf 'TPM already installed: %s\n' "$tpm_dir"
    return
  fi

  # Do not overwrite an unrelated directory. Moving it to a timestamped
  # backup keeps the install reversible and follows the link backup policy.
  if [ -e "$tpm_dir" ] || [ -L "$tpm_dir" ]; then
    backup_target "$tpm_dir"
  fi

  mkdir -p "$tmux_plugin_dir"
  git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
  printf 'Installed TPM to %s\n' "$tpm_dir"
}

deploy_windows_terminal() {
  # Windows Terminal reads settings.json from the Windows side; a WSL symlink
  # into /mnt/c is not resolved by the Windows process, so copy the file
  # instead of linking it. This step only runs under WSL.
  command -v cmd.exe >/dev/null 2>&1 || {
    printf 'Skipping Windows Terminal (not WSL): cmd.exe not found.\n'
    return 0
  }

  win_localappdata=$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')
  [ -n "$win_localappdata" ] || {
    printf 'Skipping Windows Terminal: could not resolve %%LOCALAPPDATA%%.\n'
    return 0
  }

  # Convert C:\Users\name\AppData\Local -> /mnt/c/Users/name/AppData/Local
  drive=$(printf '%s' "$win_localappdata" | cut -c1 | tr 'A-Z' 'a-z')
  rest=$(printf '%s' "$win_localappdata" | cut -c3- | tr '\\' '/')
  wt_packages="/mnt/${drive}${rest}/Packages"

  # Locate the per-user package settings, preferring stable over Preview.
  settings_target=""
  for candidate in "$wt_packages"/Microsoft.WindowsTerminal*/LocalState/settings.json; do
    [ -e "$candidate" ] || continue
    case "$candidate" in
      *Preview*) : ;;
      *) settings_target=$candidate; break ;;
    esac
  done

  [ -n "$settings_target" ] || {
    printf 'Skipping Windows Terminal: no per-user settings.json under %s\n' "$wt_packages"
    return 0
  }

  if [ -e "$settings_target" ]; then
    backup_target "$settings_target"
  fi
  mkdir -p "$(dirname "$settings_target")"
  cp "$repo_dir/windows-terminal/settings.json" "$settings_target"
  printf 'Installed Windows Terminal settings -> %s\n' "$settings_target"
}

if ! command -v git >/dev/null 2>&1; then
  printf '%s\n' 'Error: git is required to install TPM.' >&2
  exit 1
fi

install_tpm

link_config "$repo_dir/nvim" "$config_dir/nvim"
link_config "$repo_dir/tmux/tmux.conf" "$config_dir/tmux/tmux.conf"
link_config "$repo_dir/tmux/colors.conf" "$config_dir/tmux/colors.conf"
link_config "$repo_dir/fish/config.fish" "$config_dir/fish/config.fish"
for fish_file in "$repo_dir"/fish/conf.d/*.fish; do
  fish_name=${fish_file##*/}
  link_config "$fish_file" "$config_dir/fish/conf.d/$fish_name"
done
link_config "$repo_dir/fish/fish_plugins" "$config_dir/fish/fish_plugins"
link_config "$repo_dir/starship/starship.toml" "$config_dir/starship.toml"

deploy_windows_terminal

printf 'Dotfiles installed.\n'
printf 'TPM plugins:           %s\n' "$tmux_plugin_dir"
printf 'Fish config:           %s\n' "$config_dir/fish"
printf 'Reload tmux with:  tmux source-file %s\n' "$config_dir/tmux/tmux.conf"
printf 'Reload fish with:  exec fish\n'
