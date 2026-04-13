#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/scripts/lib.sh"

log "${BLUE}🚀 Starting Linux sudo setup...${NC}"

if [ "$(uname -s)" != "Linux" ]; then
  log "${RED}❌ This script is for Linux only.${NC}"
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  log "${RED}❌ sudo is required for this installer. Use install_linux_nosudo.sh instead.${NC}"
  exit 1
fi

. /etc/os-release
DISTRO="${ID:-unknown}"
SUDO="sudo"

log "${GREEN}🐧 Detected Linux (${DISTRO})${NC}"
log "${BLUE}📦 Installing packages...${NC}"

case "$DISTRO" in
  ubuntu|debian|pop|kali|linuxmint)
    $SUDO apt-get update
    $SUDO apt-get install -y git zsh curl wget unzip fontconfig fzf ripgrep fd-find tmux tree bat jq gh direnv btop just ffmpeg poppler-utils imagemagick p7zip-full chafa
    if ! command -v eza >/dev/null 2>&1; then
      if command -v cargo >/dev/null 2>&1; then
        cargo install eza
      fi
    fi
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
      ensure_dir "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
      ensure_dir "$HOME/.local/bin"
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
    ;;
  fedora|rhel|centos)
    $SUDO dnf install -y git zsh curl wget unzip fontconfig fzf ripgrep fd-find tmux tree bat jq gh direnv btop just ffmpeg poppler-utils ImageMagick p7zip p7zip-plugins chafa
    if command -v dnf >/dev/null 2>&1; then
      $SUDO dnf install -y eza || true
    fi
    ;;
  arch|manjaro|endeavouros)
    $SUDO pacman -Sy --noconfirm git zsh curl wget unzip fzf ripgrep fd tmux tree bat jq github-cli direnv btop just ffmpeg poppler imagemagick p7zip chafa eza
    ;;
  *)
    log "${RED}❌ Unsupported distro: ${DISTRO}.${NC}"
    log "${YELLOW}Install the core packages manually, then rerun the config-copy steps if needed.${NC}"
    exit 1
    ;;
esac

if ! command -v starship >/dev/null 2>&1; then
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
fi

if ! command -v zoxide >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if ! command -v lazygit >/dev/null 2>&1; then
  log "${YELLOW}⚠️ lazygit was not installed by the package manager. Install it manually if you want the terminal Git UI.${NC}"
fi

if ! command -v atuin >/dev/null 2>&1; then
  log "${YELLOW}⚠️ atuin is not available from this package path. Install it manually if you want synced shell history.${NC}"
fi

if ! command -v yazi >/dev/null 2>&1; then
  log "${YELLOW}⚠️ yazi is not available from this package path. Install it manually if you want the terminal file manager.${NC}"
fi

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

if ! command -v glow >/dev/null 2>&1; then
  log "${YELLOW}⚠️ glow is not available from this package path. Install it manually if needed.${NC}"
fi

configure_linux_font_system "$SUDO"
finalize_setup "Linux"
