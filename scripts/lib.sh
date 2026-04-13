#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$HOME/.zsh/plugins"

log() {
  printf "%b\n" "$1"
}

ensure_dir() {
  mkdir -p "$1"
}

copy_file() {
  local src=$1
  local dest=$2

  ensure_dir "$(dirname "$dest")"
  if [ -f "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
  fi
  cp "$src" "$dest"
  printf "   Copied %s -> %s\n" "$src" "$dest"
}

copy_dir() {
  local src=$1
  local dest=$2

  ensure_dir "$(dirname "$dest")"
  if [ -d "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
  fi
  cp -R "$src" "$dest"
  printf "   Copied %s -> %s\n" "$src" "$dest"
}

clone_or_update() {
  local repo_url=$1
  local dest_dir=$2
  if [ -d "$dest_dir/.git" ]; then
    (cd "$dest_dir" && git pull --quiet)
  elif [ -d "$dest_dir" ]; then
    rm -rf "$dest_dir"
    git clone --quiet "$repo_url" "$dest_dir"
  else
    git clone --quiet "$repo_url" "$dest_dir"
  fi
}

install_zsh_plugins() {
  log "${BLUE}🔌 Setting up Zsh plugins...${NC}"
  ensure_dir "$PLUGIN_DIR"
  clone_or_update "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
  clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting" "$PLUGIN_DIR/zsh-syntax-highlighting"
  clone_or_update "https://github.com/zsh-users/zsh-history-substring-search" "$PLUGIN_DIR/zsh-history-substring-search"
  clone_or_update "https://github.com/Aloxaf/fzf-tab" "$PLUGIN_DIR/fzf-tab"
}

setup_bat_theme() {
  log "${BLUE}🦇 Setting up Bat theme (Tokyo Night)...${NC}"
  local bat_cmd="bat"
  if command -v batcat >/dev/null 2>&1; then
    bat_cmd="batcat"
  fi

  if command -v "$bat_cmd" >/dev/null 2>&1; then
    local bat_config_dir
    bat_config_dir="$($bat_cmd --config-dir)"
    ensure_dir "$bat_config_dir/themes"
    curl -fsSL "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme" \
      -o "$bat_config_dir/themes/tokyonight_night.tmTheme"
    "$bat_cmd" cache --build >/dev/null
  else
    log "${YELLOW}⚠️ Bat not found, skipping theme setup.${NC}"
  fi
}

copy_configs() {
  log "${BLUE}📁 Copying configurations...${NC}"
  copy_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  copy_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
  copy_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  copy_dir "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
  copy_dir "$DOTFILES_DIR/.config/yazi" "$HOME/.config/yazi"
}

configure_git_defaults() {
  log "${BLUE}🧰 Configuring Git productivity defaults...${NC}"
  if command -v delta >/dev/null 2>&1; then
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    git config --global merge.conflictstyle zdiff3
  fi
}

silence_login() {
  log "${BLUE}🤫 Silencing login banner...${NC}"
  touch "$HOME/.hushlogin"
}

configure_linux_font_local() {
  if ! command -v fc-list >/dev/null 2>&1; then
    return
  fi

  if fc-list : family=JetBrainsMono | grep -q "Nerd Font"; then
    log "${GREEN}✅ JetBrainsMono Nerd Font is already installed.${NC}"
    return
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    log "${YELLOW}⚠️ unzip not found, skipping Nerd Font installation.${NC}"
    return
  fi

  log "${BLUE}🔤 Installing JetBrainsMono Nerd Font locally...${NC}"
  local font_dir="$HOME/.local/share/fonts"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  ensure_dir "$font_dir"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -o "$tmp_dir/font.zip"
  unzip -q "$tmp_dir/font.zip" -d "$tmp_dir"
  mv "$tmp_dir"/*.ttf "$font_dir/"
  rm -rf "$tmp_dir"
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -fv >/dev/null
  fi
}

configure_linux_font_system() {
  local sudo_cmd=$1

  if ! command -v fc-list >/dev/null 2>&1; then
    return
  fi

  if fc-list : family=JetBrainsMono | grep -q "Nerd Font"; then
    log "${GREEN}✅ JetBrainsMono Nerd Font is already installed.${NC}"
    return
  fi

  log "${BLUE}🔤 Installing JetBrainsMono Nerd Font...${NC}"
  local font_dir="/usr/local/share/fonts/JetBrainsMonoNerd"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  "$sudo_cmd" mkdir -p "$font_dir"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -o "$tmp_dir/font.zip"
  unzip -q "$tmp_dir/font.zip" -d "$tmp_dir"
  "$sudo_cmd" mv "$tmp_dir"/*.ttf "$font_dir/"
  rm -rf "$tmp_dir"
  if command -v fc-cache >/dev/null 2>&1; then
    "$sudo_cmd" fc-cache -fv >/dev/null
  fi
}

configure_shell_if_possible() {
  local os_name=$1
  log "${BLUE}🐚 Checking shell...${NC}"

  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [ -z "$zsh_path" ]; then
    log "${YELLOW}⚠️ zsh not found. Install it manually and rerun the shell change step.${NC}"
    return
  fi

  local current_shell=""
  if [ "$os_name" = "Darwin" ]; then
    current_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  elif command -v getent >/dev/null 2>&1; then
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  fi

  if [ "${current_shell:-}" = "$zsh_path" ]; then
    log "${GREEN}✅ You are already using Zsh.${NC}"
    return
  fi

  log "${YELLOW}⚠️ Run this manually to switch shells:${NC} chsh -s $zsh_path"
}

finalize_setup() {
  local os_name=$1
  install_zsh_plugins
  setup_bat_theme
  copy_configs
  configure_git_defaults
  silence_login
  configure_shell_if_possible "$os_name"
  log "${GREEN}✨ Setup complete. Open a new terminal or run: exec zsh -l${NC}"
}
