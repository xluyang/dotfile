# Fish, Fisher, and Starship

Fish is the interactive shell in this dotfiles repository, with Starship as the
prompt. Scripts keep their own shebang (for example, `#!/usr/bin/env bash`),
and no configuration here calls `chsh`; switching the login shell is optional.

## Installation

On Ubuntu/WSL, install Fish and the command-line dependencies with:

```sh
sudo apt update
sudo apt install -y fish fzf curl git
```

Fish 4.x is expected. Install Fisher in a Fish process with:

```sh
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; and fisher install jorgebucaran/fisher'
```

The repository manifest installs the selected plugins (no prompt plugin — the
prompt is handled by Starship, not a Fisher plugin):

```sh
fish -c 'fisher install jethrokuan/z patrickf1/fzf.fish franciscolourenco/done edc/bass jorgebucaran/nvm.fish'
```

`gazorby/fish-autopair` was not included because Fisher currently reports that
repository as unavailable. Add a maintained fork only after checking its source
and compatibility with Fish 4.x.

Run `./install.sh` to link the repository-managed files, then synchronize the
manifest whenever it changes:

```sh
./install.sh
fish -c 'fisher update'
```

The installer links `config.fish`, files under `conf.d/`, and `fish_plugins`
individually. It does not replace Fisher-generated functions/completions,
plugin `conf.d` files, or `fish_variables`.

## Layout

- `config.fish`: entry point; initializes Starship for interactive shells.
- `conf.d/00_env.fish`: Fish-only paths and WSL gateway detection.
- `conf.d/05_rustup.fish`: loads Cargo's Fish environment when present.
- `conf.d/10_aliases.fish`: interactive aliases (`lg`, `eza`).
- `conf.d/15_ai_env.fish`: Claude Code / DeepSeek non-sensitive environment.
- `conf.d/19_local.fish`: sources `~/.config/fish/fish.local` when present
  (the Fish equivalent of the old `~/.zshenv.local`; never committed).
- `conf.d/20_functions.fish`: WSL proxy helpers, `denter`, `bst_sdk_*` SDK
  shortcuts, and the yazi `y` helper.
- `fish_plugins`: Fisher manifest (z, fzf.fish, done, bass, nvm.fish).

## Prompt

Starship owns the prompt; `config.fish` runs `starship init fish` when the
binary is available. The theme is defined in `starship/starship.toml` (Catppuccin
Mocha, two-line). If Starship is missing, Fish falls back to its default prompt.

## nvm (Node.js version manager)

`nvm.fish` is a Fish-native nvm wrapper listed in `fish_plugins`. It stores
Node versions in `nvm_data` (`~/.local/share/nvm` by default), so no `NVM_DIR`
is needed. Install Fisher and synchronize the manifest first:

```sh
fish -c 'fisher update'
```

Install a Node version and set it as the global default:

```fish
# Install the latest LTS version
nvm install lts

# Set the global default Node version
set -U nvm_default_version lts
```

Verify that Fish picks up `node` and `npm`:

```fish
node -v
npm -v
```

Common commands:

| Operation | Command |
| --- | --- |
| Install a specific version | `nvm install 20` |
| Switch the current version | `nvm use 20` |
| List installed versions | `nvm ls` |
| Switch to the latest LTS | `nvm use lts` |

## Docker SDK helpers

`denter` is the generic entry point: it starts a stopped container, then enters
it with a chosen work directory, user, and shell. The SDK shortcuts are thin
wrappers:

```fish
bst_sdk_25.2.0   # denter c1200_evkit_docker_sdk-v25.2.0 /workspace/host_folder
bst_sdk_2.3.0.4  # denter a1000b-sdk-fad-2.3.0.4 /home
hanhai-sdk-2000  # denter hanhai-sdk-manager-a2000-25 /home/share_mount
```

Container names complete with Tab via the `complete` line in
`conf.d/20_functions.fish`.

## Existing Fish configuration

Do not symlink the entire `~/.config/fish` directory. Keep Fisher's generated
files and `fish_variables` in place. `./install.sh` backs up an existing
`config.fish` or managed module before linking the repository version; review
the timestamped backup if local settings were not already migrated. Add future
customizations as new `conf.d/` modules rather than editing generated plugin
files. Machine-specific secrets go in `~/.config/fish/fish.local` (sourced by
`conf.d/19_local.fish`), which is never committed.

## Verification

```sh
fish --version
fish -c 'type -q fisher; and fisher --version'
fish -c 'fisher list'
starship --version
fish -n "$HOME/.config/fish/config.fish"
```

Start an interactive Fish shell with `fish` to inspect the Starship prompt.
