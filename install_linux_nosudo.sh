#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/scripts/lib.sh"

log "${BLUE}🚀 Starting Linux no-sudo setup...${NC}"

if [ "$(uname -s)" != "Linux" ]; then
  log "${RED}❌ This script is for Linux only.${NC}"
  exit 1
fi

ensure_dir "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

install_local_script() {
  local check_cmd=$1
  local install_cmd=$2
  if ! command -v "$check_cmd" >/dev/null 2>&1; then
    eval "$install_cmd"
  fi
}

install_binary_tarball() {
  local name=$1
  local url=$2

  if command -v "$name" >/dev/null 2>&1 || [ -z "$url" ]; then
    return
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL "$url" | tar xz -C "$tmp_dir"
  local found
  found="$(find "$tmp_dir" -type f -name "$name" | head -n 1)"
  if [ -n "$found" ]; then
    mv "$found" "$HOME/.local/bin/$name"
    chmod +x "$HOME/.local/bin/$name"
  fi
  rm -rf "$tmp_dir"
}

ARCH="$(uname -m)"

log "${BLUE}📦 Installing local tooling...${NC}"
install_local_script "starship" 'sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y -b "$HOME/.local/bin"'
install_local_script "zoxide" 'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
install_local_script "uv" 'curl -LsSf https://astral.sh/uv/install.sh | sh'
install_local_script "mise" 'curl -fsSL https://mise.run | sh'

if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin --no-key-bindings --no-completion --no-update-rc
  ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
fi

if [ "$ARCH" = "x86_64" ]; then
  install_binary_tarball "eza" "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
  install_binary_tarball "bat" "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz"
  install_binary_tarball "rg" "https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz"
  install_binary_tarball "fd" "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz"
  install_binary_tarball "lazygit" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$(uname -s)_x86_64.tar.gz"
elif [ "$ARCH" = "aarch64" ]; then
  install_binary_tarball "eza" "https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
  install_binary_tarball "bat" "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-unknown-linux-gnu.tar.gz"
  install_binary_tarball "rg" "https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-aarch64-unknown-linux-gnu.tar.gz"
fi

if ! command -v tree >/dev/null 2>&1; then
  log "${YELLOW}⚠️ tree not installed in no-sudo mode. Use 'eza --tree' instead.${NC}"
fi

if ! command -v tmux >/dev/null 2>&1; then
  log "${YELLOW}⚠️ tmux not installed in no-sudo mode. Install a static build manually if required.${NC}"
fi

if ! command -v nvim >/dev/null 2>&1; then
  log "${YELLOW}⚠️ nvim not installed in no-sudo mode. Install Neovim manually or add a local binary.${NC}"
fi

if ! command -v yazi >/dev/null 2>&1; then
  log "${YELLOW}⚠️ yazi not installed in no-sudo mode. Install it manually if you want the file manager.${NC}"
fi

configure_linux_font_local
finalize_setup "Linux"
