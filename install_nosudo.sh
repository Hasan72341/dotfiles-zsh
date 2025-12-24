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
echo -e "${BLUE}📦 Installing CLI tools...${NC}"

ARCH=$(uname -m)
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')

install_binary() {
    local name=$1
    local url=$2
    local binary_path_in_tar=$3
    
    if ! command -v "$name" &> /dev/null; then
        echo "   Installing $name via binary..."
        TMP_DIR=$(mktemp -d)
        if curl -L "$url" | tar xz -C "$TMP_DIR"; then
            find "$TMP_DIR" -type f -name "$binary_path_in_tar" -exec mv {} "$HOME/.local/bin/$name" \;
            chmod +x "$HOME/.local/bin/$name"
            echo "   ✅ $name installed."
        else
            echo "   ❌ Failed to download $name."
        fi
        rm -rf "$TMP_DIR"
    fi
}

# Eza binary
if [ "$ARCH" = "x86_64" ]; then
    EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
elif [ "$ARCH" = "aarch64" ]; then
    EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
fi
[ -n "$EZA_URL" ] && install_binary "eza" "$EZA_URL" "eza"

# Bat binary
if [ "$ARCH" = "x86_64" ]; then
    BAT_URL="https://github.com/sharkdp/bat/releases/latest/download/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz"
    install_binary "bat" "$BAT_URL" "bat"
fi

# Ripgrep binary
if [ "$ARCH" = "x86_64" ]; then
    RG_URL="https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz"
    install_binary "rg" "$RG_URL" "rg"
fi

# Fallback to Cargo if binaries failed or arch mismatch
if ! command -v eza &> /dev/null || ! command -v bat &> /dev/null || ! command -v rg &> /dev/null; then
    if ! command -v cargo &> /dev/null; then
        echo -e "${YELLOW}⚠️  Some binaries failed. Attempting Rust/Cargo install...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    if command -v cargo &> /dev/null; then
        command -v eza &> /dev/null || cargo install eza
        command -v bat &> /dev/null || cargo install --locked bat
        command -v rg &> /dev/null  || cargo install ripgrep
    fi
fi

# 5.5 Tree (Binary approach)
if ! command -v tree &> /dev/null; then
    echo "   Tree not found, skipping compilation (complex without sudo deps). Use 'eza --tree' instead."
fi

# 6. Setup Zsh Plugins
echo -e "${BLUE}🔌 Setting up Zsh plugins...${NC}"
PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

clone_or_update() {
    local repo_url=$1
    local dest_dir=$2
    if [ -d "$dest_dir" ]; then
        (cd "$dest_dir" && git pull --quiet)
    else
        echo "   Cloning $(basename "$dest_dir")..."
        git clone --quiet "$repo_url" "$dest_dir"
    fi
}

clone_or_update "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting" "$PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_update "https://github.com/zsh-users/zsh-history-substring-search" "$PLUGIN_DIR/zsh-history-substring-search"

# 7. Copy Configurations
echo -e "${BLUE}📁 Copying configurations...${NC}"
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

copy_file() {
    local src=$1
    local dest=$2
    
    mkdir -p "$(dirname "$dest")"
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$dest.bak.$(date +%s)"
    fi
    cp "$src" "$dest"
    echo "   Copied $src -> $dest"
}

copy_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
copy_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
copy_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# 8. Silence Login
touch "$HOME/.hushlogin"

echo -e "${GREEN}✨ Setup complete!${NC}"

# Automatically switch to zsh
ZSH_PATH=$(which zsh)
if [ -n "$ZSH_PATH" ]; then
    echo -e "${BLUE}🔄 Switching to Zsh now...${NC}"
    exec "$ZSH_PATH" -l
else
    echo -e "${YELLOW}⚠️ Zsh not found. Please run: source ~/.bashrc${NC}"
fi
