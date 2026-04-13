# Tooling Guide

This repo is now a complete terminal environment rather than a single prompt theme. It covers shell UX, navigation, fuzzy finding, Git workflows, terminal multiplexing, editor setup, task running, environment management, and file management.

## What Changed

### Shell

- `.zshrc` was rebuilt around a modern interactive shell workflow.
- It now sets `XDG_*` directories, better history behavior, stronger completion styles, `fzf-tab`, and interactive shell guards so non-interactive shells do not trip over prompt bindings.
- `zsh-autosuggestions`, `zsh-history-substring-search`, `zsh-syntax-highlighting`, `atuin`, `zoxide`, `mise`, and `direnv` are initialized when available.
- The shell now exports:
  - `EDITOR=nvim`
  - `VISUAL=nvim`
  - `PAGER=delta`
  - `MANPAGER='sh -c "col -bx | bat -l man -p"'`
- Productivity aliases were added for Git, Python, Markdown preview, system monitoring, and file navigation.
- `yazi` is wrapped so when you exit the file manager, your shell follows the last directory you navigated to.

### Prompt

- `starship.toml` was replaced with a tighter two-line Tokyo Night prompt.
- It shows platform, user, host, current directory, Git branch and status, language runtimes, command duration, and time.
- A transient Enter prompt keeps command history visually cleaner after execution.

### Neovim

- A full LazyVim-based config lives under `.config/nvim`.
- `init.lua` boots the local config.
- `config/options.lua` sets editor defaults like relative numbers, split directions, clipboard integration, and timing.
- `config/keymaps.lua` adds shortcuts for Todo Telescope, LazyGit, and relative number toggling.
- `config/lazy.lua` bootstraps `lazy.nvim` and imports LazyVim plus selected extras.
- `plugins/colorscheme.lua` sets Tokyo Night as the active theme.
- `plugins/editor.lua` customizes the dashboard, bufferline, lualine, and LazyGit integration.

### tmux

- `.tmux.conf` was added to make multiplexing match the rest of the setup.
- Prefix is `Ctrl-a`.
- Mouse support is enabled.
- Windows and panes start at index 1.
- Splits inherit the current pane’s working directory.
- Vim-style pane navigation and resizing are configured.
- The status bar uses Tokyo Night colors and sits at the top.

### Yazi

- `.config/yazi` was added so the terminal file manager has an explicit config instead of relying on defaults.
- `yazi.toml` enables hidden files, natural sorting, editor openers, and preview tuning.
- `keymap.toml` adds quick jumps and shell integrations.
- `theme.toml` points to Tokyo Night styling.

### Installers

- The repo now uses three explicit entrypoints instead of one mixed installer:
  - `install_mac.sh`
  - `install_linux_sudo.sh`
  - `install_linux_nosudo.sh`
- Shared behavior lives in `scripts/lib.sh`.
- The macOS installer provisions the full stack through Homebrew.
- The Linux sudo installer uses the distro package manager first, then falls back to upstream installers for some tools.
- The Linux no-sudo installer focuses on local user-space installs and warns clearly when a tool still needs a manual binary.
- The installers now install or wire:
  - Base shell tools: `starship`, `zoxide`, `fzf`, `eza`, `bat`, `ripgrep`, `fd`
  - Shell/editor extras: `neovim`, `lazygit`, `atuin`, `fastfetch`
  - Productivity tooling: `uv`, `mise`, `direnv`, `yazi`, `gh`, `git-delta`, `glow`, `just`, `btop`
  - Yazi/archive/preview dependencies: `p7zip`, `chafa`, `ffmpeg`, `poppler`, `imagemagick`
- All installers copy `.zshrc`, `.tmux.conf`, `starship.toml`, `.config/nvim`, and `.config/yazi` into the home directory.
- All installers also configure global Git defaults so `delta` is used as the pager and `zdiff3` merge conflicts are enabled.

## Tool-by-Tool Tutorial

### Zsh

Purpose:
- Your interactive shell and command environment.

Important behavior:
- Better history sharing and deduplication.
- Better completion matching.
- `fzf-tab` upgrades tab completion into a searchable UI.
- Autosuggestions show likely command completions inline.

Useful habits:
- Press `Tab` on commands, file paths, branches, and directories to use the enhanced completion UI.
- Use the up/down arrows on a partial command to search history by prefix.

### Starship

Purpose:
- Cross-shell prompt engine.

What it shows:
- System, user, host, path, Git state, language versions, elapsed command time, and clock.

Why it matters:
- Fast situational awareness without manually running extra commands.

### Atuin

Purpose:
- Smarter shell history.

Usage:
- Keep typing part of an old command and use history navigation.
- If you enable its daemon/service later, history sync and search become faster and richer.

Recommended:
- `brew services start atuin`

### Zoxide

Purpose:
- Frecency-based directory jumping.

Usage:
- `cd project-name`
- `z foo`

Why it matters:
- Replaces repetitive `cd ~/some/deep/path`.

### FZF and fzf-tab

Purpose:
- Fuzzy filtering for files, commands, history, and completions.

Usage:
- `Ctrl-T` to fuzzy-pick files.
- `Alt-C` to fuzzy-pick directories.
- `Tab` now opens a fuzzy selection UI for many completions.

### Eza

Purpose:
- Better `ls`.

Usage:
- `ls`
- `ll`
- `lt`

Why it matters:
- Icons, Git metadata, clearer directory-first layouts.

### Bat

Purpose:
- Better `cat`.

Usage:
- `cat file`

Why it matters:
- Syntax highlighting and better pager behavior, including manual pages.

### Ripgrep and fd

Purpose:
- Fast text search and fast file discovery.

Usage:
- `rg "needle"`
- `fd config`

Why it matters:
- These are foundational tools for navigating large codebases quickly.

### UV

Purpose:
- Fast Python package and environment tooling.

Usage:
- `py script.py`
- `uv venv`
- `uv pip install ruff`
- `uv run pytest`

Why it matters:
- Much faster and cleaner than juggling raw `pip` in many workflows.

### Mise

Purpose:
- Runtime and tool version management.

Usage:
- `mise use -g node@latest`
- `mise use python@3.12`
- `mise ls`

Why it matters:
- Keeps language runtimes reproducible across projects.

### Direnv

Purpose:
- Per-directory environment loading.

Usage:
1. Create `.envrc`
2. Add exports or layout commands
3. Run `direnv allow`

Why it matters:
- Project-specific environment variables load automatically when you enter a directory.

### Yazi

Purpose:
- Fast terminal file manager.

Usage:
- `y`

What changed:
- Exiting Yazi returns you to the last directory you were in.
- Basic openers and quick-jump keymaps were added.
- The theme config was kept local-only to avoid relying on missing external flavor packages.

Why the 7z error happened:
- Yazi can inspect archives, but the machine had no `7z` or `7zz` binary installed.
- Installing `p7zip` fixes that archive support gap.

Extra preview dependencies:
- `chafa` for terminal image rendering
- `ffmpeg` for media metadata and thumbnails
- `poppler` for PDF previews
- `imagemagick` for broader image conversion support

### GitHub CLI (`gh`)

Purpose:
- GitHub operations from the terminal.

Usage:
- `gh auth login`
- `gh repo clone owner/repo`
- `gh pr status`
- `ghv`

### Delta

Purpose:
- Better Git diffs.

Usage:
- `git diff`
- `git show`

Why it matters:
- Cleaner syntax-aware diffs and navigation.

### LazyGit

Purpose:
- Fast terminal Git UI.

Usage:
- `lg`
- In Neovim: `<leader>gg`

### Glow

Purpose:
- Render Markdown nicely in the terminal.

Usage:
- `md README.md`

### Just

Purpose:
- Lightweight command runner for project tasks.

Usage:
- Create a `justfile`
- Run `just`
- Run `just test`

Why it matters:
- Cleaner than remembering long scripts for common tasks.

### Btop

Purpose:
- Terminal system monitor.

Usage:
- `btop`
- `top` also points to `btop`

### tmux

Purpose:
- Persist and manage multiple terminal sessions.

Usage:
- `tmux`
- Prefix is `Ctrl-a`
- Split horizontally: `Ctrl-a |`
- Split vertically: `Ctrl-a -`
- New window: `Ctrl-a c`
- Reload config: `Ctrl-a r`

Why it matters:
- Lets you keep long-running sessions, editors, logs, and shells open without relying on a single terminal window.

### Neovim + LazyVim

Purpose:
- Main editor setup.

Usage:
- `nvim`
- `<leader>gg` opens LazyGit
- `<leader>ft` opens Todo Telescope

Why it matters:
- Gives you a batteries-included modern Neovim environment while keeping your local overrides small and understandable.

## Recommended First-Run Commands

Run these once in a fresh shell:

```zsh
exec zsh -l
gh auth login
brew services start atuin
tmux
y
nvim
```

## Core Daily Commands

```zsh
v                 # nvim
lg                # lazygit
y                 # yazi with cwd handoff
j                 # just
py script.py      # uv-backed python run
ff                # fastfetch
glog              # git graph
gs                # git status -sb
md README.md      # render markdown
btop              # system monitor
```

## Files To Know

- `.zshrc`: main shell behavior
- `starship.toml`: prompt layout
- `.tmux.conf`: terminal multiplexer
- `.config/nvim`: editor setup
- `.config/yazi`: file manager setup
- `install_mac.sh`: macOS bootstrap script
- `install_linux_sudo.sh`: Linux bootstrap script for sudo environments
- `install_linux_nosudo.sh`: Linux bootstrap script for restricted environments
- `scripts/lib.sh`: shared installer helpers
