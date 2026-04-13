# Dotfiles

My personal configuration files for Zsh, Starship, Neovim, and modern terminal tooling. Designed to work on macOS, Linux (Debian/Ubuntu, Fedora, Arch), and even systems without `sudo` access.

## Features

- **Shell:** Zsh with `zsh-autosuggestions`, `zsh-history-substring-search`, `fzf-tab`, syntax-highlighting, `atuin`, `fzf`, and `zoxide`.
- **Prompt:** [Starship](https://starship.rs/) with a Tokyo Night prompt, transient enter behavior, and a two-line layout tuned for Nerd Fonts.
- **Editor:** `nvim` with a bundled [LazyVim](https://www.lazyvim.org/) setup and Tokyo Night theming.
- **Tools:** Installs `tmux`, `fzf`, `zoxide`, `eza`, `bat`, `ripgrep`, `fd`, `lazygit`, `fastfetch`, `atuin`, `uv`, `mise`, `direnv`, `yazi`, `gh`, `delta`, `glow`, `just`, `btop`, and Yazi preview/archive dependencies where the platform supports them.
- **Themes:** Tokyo Night styling applied across Starship, `bat`, and Neovim.
- **Installers:** Separate scripts for `macOS`, `Linux with sudo`, and `Linux without sudo`.

## Installer Matrix

| Environment | Script |
|-------------|--------|
| macOS | `./install_mac.sh` |
| Linux with `sudo` | `./install_linux_sudo.sh` |
| Linux without `sudo` | `./install_linux_nosudo.sh` |

## Installation

### macOS

```bash
git clone https://github.com/Hasan72341/dotfiles-zsh.git ~/dotfiles-zsh
~/dotfiles-zsh/install_mac.sh
```

### Linux With `sudo`

```bash
git clone https://github.com/Hasan72341/dotfiles-zsh.git ~/dotfiles-zsh
~/dotfiles-zsh/install_linux_sudo.sh
```

### Linux Without `sudo`

```bash
git clone https://github.com/Hasan72341/dotfiles-zsh.git ~/dotfiles-zsh
~/dotfiles-zsh/install_linux_nosudo.sh
```

## What's Included

| File | Description |
|------|-------------|
| `install_mac.sh` | macOS installer using Homebrew. |
| `install_linux_sudo.sh` | Linux installer for systems where you have `sudo`. |
| `install_linux_nosudo.sh` | Linux installer for restricted environments without `sudo`. |
| `scripts/lib.sh` | Shared helper functions used by all installers. |
| `.zshrc` | Zsh configuration with plugins and aliases. |
| `.tmux.conf` | tmux productivity profile with Vim-style navigation and Tokyo Night colors. |
| `starship.toml` | Cyber-inspired Tokyo Night prompt configuration. |
| `.config/nvim` | LazyVim bootstrap and local UI/editor overrides. |
| `.config/yazi` | Yazi file manager config. |
| `TOOLING.md` | Full tooling tutorial and modification guide. |

## Documentation

- Read [`TOOLING.md`](./TOOLING.md) for a complete walkthrough of the shell, prompt, Neovim, tmux, Yazi, Git tooling, and the modifications made in this repo.
