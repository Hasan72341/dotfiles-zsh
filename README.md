# Dotfiles

My personal configuration files for Zsh, Bash, Starship, and essential terminal tools. Designed to work on macOS, Linux (Debian/Ubuntu, Fedora, Arch), and even systems without `sudo` access.

## Features

- **Shell:** Zsh (default) with `zsh-autosuggestions` and `syntax-highlighting`. Bash support included.
- **Prompt:** [Starship](https://starship.rs/) with a custom Tokyo Night preset and transient prompt (minimalist `❯` after command execution).
- **Tools:** Automatically installs `tmux`, `tree`, `fzf`, `zoxide`, `eza` (modern ls), `bat` (modern cat), and `ripgrep`.
- **Themes:** Tokyo Night theme applied to Starship and `bat`.
- **Cross-Platform:** Auto-detects OS and uses the appropriate package manager (`brew`, `apt`, `dnf`, `pacman`).

## Installation

### Standard (Recommended)
Use this if you have `sudo` access or are on your personal machine.

```bash
git clone https://github.com/Hasan72341/dotfiles-zsh.git ~/dotfiles-zsh
~/dotfiles-zsh/install.sh
```

### Non-Sudo (Restricted Environments)
Use this on shared servers or systems where you don't have root access. It installs everything locally to `~/.local/bin`.

```bash
git clone https://github.com/Hasan72341/dotfiles-zsh.git ~/dotfiles-zsh
~/dotfiles-zsh/install_nosudo.sh
```

## What's Included

| File | Description |
|------|-------------|
| `install.sh` | Main setup script. Installs packages via system manager, copies configs, and sets Zsh as default. |
| `install_nosudo.sh` | Fallback script. Installs binaries locally, compiles `tree`, uses `tmux` AppImage, and configures Bash. |
| `.zshrc` | Zsh configuration with plugins and aliases. |
| `.bashrc` | Bash configuration mirroring the Zsh setup (for non-sudo usage). |
| `starship.toml` | Cyber-inspired Tokyo Night prompt configuration. |
