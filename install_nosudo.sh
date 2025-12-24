#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Non-Sudo (User Mode) Setup...${NC}"

# 1. Setup Directories
echo -e "${BLUE}📂 Setting up local directories...${NC}"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 2. Install Starship (Local)
if ! command -v starship &> /dev/null; then
    echo -e "${YELLOW}⭐ Installing Starship (local)...${NC}"
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y -b "$HOME/.local/bin"
fi

# 3. Install Zoxide (Local)
if ! command -v zoxide &> /dev/null; then
    echo -e "${YELLOW}📂 Installing Zoxide...${NC}"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# 4. Install FZF (Local)
if [ ! -d "$HOME/.fzf" ]; then
    echo -e "${YELLOW}🔍 Installing FZF...${NC}"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --bin --no-key-bindings --no-completion --no-update-rc
    ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
fi

# 5. Install Rust-based tools (eza, bat, ripgrep)
# Since we have no sudo, Cargo is the best way.

if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}⚠️  Rust/Cargo not found. Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

if command -v cargo &> /dev/null; then
    echo -e "${GREEN}🦀 Cargo detected. Installing utils via Rust...${NC}"
    command -v eza &> /dev/null || cargo install eza
    command -v bat &> /dev/null || cargo install --locked bat
    command -v rg &> /dev/null  || cargo install ripgrep
else
    echo -e "${RED}❌ Failed to install Rust. Skipping eza, bat, and ripgrep.${NC}"
fi

# 5.5 Install Tmux & Tree (Local Compilation)
echo -e "${YELLOW}🛠  Compiling Tree & Tmux (local)...${NC}"

# Tree
if ! command -v tree &> /dev/null; then
  echo "   Compiling tree..."
  mkdir -p "$HOME/.src"
  cd "$HOME/.src"
  curl -L http://mama.indstate.edu/users/ice/tree/src/tree-2.1.3.tgz -o tree.tgz
  tar -xzf tree.tgz
  cd tree-2.1.3
  make
  cp tree "$HOME/.local/bin/"
  cd ..
fi

# Tmux (Static binary approach is better, but simple compilation for now)
if ! command -v tmux &> /dev/null; then
  echo "   Tmux requires libevent/ncurses. Using AppImage (safe fallback) or skipping if unavailable."
  # Using a static build release is much safer for non-sudo than compiling from source due to deps
  curl -L https://github.com/nelsonenzo/tmux-appimage/releases/download/3.3a/tmux.appimage -o "$HOME/.local/bin/tmux"
  chmod +x "$HOME/.local/bin/tmux"
fi

# 6. Copy Configurations
echo -e "${BLUE}📁 Copying configurations...${NC}"
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

copy_file() {
    local src=$1
    local dest=$2
    
    mkdir -p "$(dirname "$dest")"
    if [ -f "$dest" ]; then
        mv "$dest" "$dest.bak.$(date +%s)"
    fi
    cp "$src" "$dest"
    echo "   Copied $src -> $dest"
}

copy_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
copy_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# 7. Silence Login
touch "$HOME/.hushlogin"

echo -e "${GREEN}✨ Setup complete!${NC}"
echo -e "Restart your terminal or run: source ~/.bashrc"
