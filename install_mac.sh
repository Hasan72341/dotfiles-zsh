#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/scripts/lib.sh"

log "${BLUE}🚀 Starting macOS setup...${NC}"

if [ "$(uname -s)" != "Darwin" ]; then
  log "${RED}❌ This script is for macOS only.${NC}"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  log "${YELLOW}🍺 Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

log "${BLUE}📦 Installing packages...${NC}"
brew install starship zoxide fzf eza bat ripgrep git wget curl tmux tree neovim fd lazygit atuin fastfetch uv mise direnv yazi gh git-delta glow just btop p7zip chafa ffmpeg poppler imagemagick
brew install --cask font-jetbrains-mono-nerd-font || true

finalize_setup "Darwin"
