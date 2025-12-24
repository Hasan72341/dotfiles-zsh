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

# 5. Install Tools (Eza, Bat, Ripgrep, Tree, Tmux)
echo -e "${BLUE}📦 Installing CLI tools...${NC}"

ARCH=$(uname -m)
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]') # linux or darwin

# Allow user to vendor binaries in dotfiles/bin/os-arch/
# Structure example: dotfiles/bin/linux-x86_64/eza
LOCAL_BIN_DIR="$DOTFILES_DIR/bin/${OS_TYPE}-${ARCH}"

install_binary() {
    local name=$1
    local url=$2
    local binary_path_in_tar=$3
    
    # 1. Check if already installed
    if command -v "$name" &> /dev/null; then
        return
    fi

    # 2. Check for local vendored binary in repo
    if [ -f "$LOCAL_BIN_DIR/$name" ]; then
        echo "   📂 Installing $name from local repo ($LOCAL_BIN_DIR)..."
        cp "$LOCAL_BIN_DIR/$name" "$HOME/.local/bin/$name"
        chmod +x "$HOME/.local/bin/$name"
        return
    fi

    # 3. Download from URL
    if [ -n "$url" ]; then
        echo "   ⬇️  Downloading $name..."
        TMP_DIR=$(mktemp -d)
        
        # Check if URL is a tarball or direct binary
        if [[ "$url" == *.tar.gz ]] || [[ "$url" == *.tgz ]]; then
            if curl -L "$url" | tar xz -C "$TMP_DIR"; then
                # Find binary ensuring we don't pick up garbage
                FOUND=$(find "$TMP_DIR" -type f -name "$name" | head -n 1)
                if [ -f "$FOUND" ]; then
                    mv "$FOUND" "$HOME/.local/bin/$name"
                    chmod +x "$HOME/.local/bin/$name"
                    echo "   ✅ $name installed."
                else
                    echo "   ❌ Extracted but $name binary not found."
                fi
            else
                echo "   ❌ Failed to download/extract $name."
            fi
        else
            # Direct binary download
            curl -L "$url" -o "$HOME/.local/bin/$name"
            chmod +x "$HOME/.local/bin/$name"
            echo "   ✅ $name installed."
        fi
        rm -rf "$TMP_DIR"
    else
        echo "   ⚠️  No download URL for $name on $OS_TYPE-$ARCH."
    fi
}

# --- Definitions ---

# Eza
EZA_URL=""
if [ "$OS_TYPE" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    elif [ "$ARCH" = "aarch64" ]; then
        EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
    fi
fi
install_binary "eza" "$EZA_URL" "eza"

# Bat (v0.24.0)
BAT_URL=""
BAT_VERSION="v0.24.0"
if [ "$OS_TYPE" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        BAT_URL="https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
    elif [ "$ARCH" = "aarch64" ]; then
        BAT_URL="https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
    fi
fi
install_binary "bat" "$BAT_URL" "bat"

# Ripgrep (14.1.0)
RG_URL=""
RG_VERSION="14.1.0"
if [ "$OS_TYPE" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    elif [ "$ARCH" = "aarch64" ]; then
        RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
    fi
fi
install_binary "rg" "$RG_URL" "rg"

# Tree (Static)
TREE_URL=""
if [ "$OS_TYPE" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        TREE_URL="https://github.com/wimpysworld/static-binaries/raw/master/tree-1.8.0-x86_64.tar.gz"
    elif [ "$ARCH" = "aarch64" ]; then
        # Alternative source for arm64 tree binary
        TREE_URL="https://github.com/PB-Web/static-binaries/raw/main/aarch64/tree"
    fi
fi
[ -n "$TREE_URL" ] && install_binary "tree" "$TREE_URL" "tree"


# Tmux (Static)
TMUX_URL=""
if [ "$OS_TYPE" = "linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        TMUX_URL="https://github.com/mjakob-gh/build-static-tmux/releases/download/v3.6a/tmux.linux-amd64.gz"
    elif [ "$ARCH" = "aarch64" ]; then
        TMUX_URL="https://github.com/mjakob-gh/build-static-tmux/releases/download/v3.6a/tmux.linux-arm64.gz"
    fi
fi
# Note: install_binary helper handles .gz via 'tar xz', but for direct .gz binary we need a small tweak
if [[ "$TMUX_URL" == *.gz ]] && [[ "$TMUX_URL" != *.tar.gz ]]; then
    if ! command -v tmux &> /dev/null; then
        echo "   ⬇️  Downloading tmux (ARM64)..."
        curl -L "$TMUX_URL" | gunzip > "$HOME/.local/bin/tmux"
        chmod +x "$HOME/.local/bin/tmux"
        echo "   ✅ tmux installed."
    fi
else
    install_binary "tmux" "$TMUX_URL" "tmux"
fi


# 5.5 Tree (Binary approach)
if ! command -v tree &> /dev/null; then
    echo "   Tree not found, skipping compilation (complex without sudo deps). Use 'eza --tree' instead."
fi

# 5.6 Install Nerd Font (Local)
echo -e "${BLUE}🔤 Checking Nerd Fonts...${NC}"
FONT_DIR="$HOME/.local/share/fonts"
LEGACY_FONT_DIR="$HOME/.fonts"

if fc-list : family=JetBrainsMono | grep -q "Nerd Font"; then
    echo -e "${GREEN}✅ JetBrainsMono Nerd Font is already installed.${NC}"
else
    if ! command -v unzip &> /dev/null; then
        echo -e "${RED}❌ 'unzip' not found. Cannot install fonts automatically.${NC}"
    else
        echo -e "${YELLOW}⬇️  Installing JetBrainsMono Nerd Font (local)...${NC}"
        mkdir -p "$FONT_DIR"
        TMP_DIR=$(mktemp -d)
        
        # Download
        curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -o "$TMP_DIR/font.zip"
        
        # Unzip
        unzip -q "$TMP_DIR/font.zip" -d "$TMP_DIR"
        
        # Move
        mv "$TMP_DIR/"*.ttf "$FONT_DIR/"
        
        # Legacy fallback
        if [ ! -d "$LEGACY_FONT_DIR" ]; then
            ln -s "$FONT_DIR" "$LEGACY_FONT_DIR"
        fi
        
        # Cleanup
        rm -rf "$TMP_DIR"
        
        # Update cache
        if command -v fc-cache &> /dev/null; then
            fc-cache -fv > /dev/null
            echo -e "${GREEN}✅ Nerd Font installed to $FONT_DIR${NC}"
        else
            echo -e "${YELLOW}⚠️  fc-cache not found. Fonts installed but might not be detected yet.${NC}"
        fi
        
        # Auto-configure GNOME Terminal if available
        if command -v gsettings &> /dev/null; then
            echo -e "${BLUE}⚙️  Configuring GNOME Terminal font...${NC}"
            PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
            if [ -n "$PROFILE_ID" ]; then
                SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"
                if gsettings set "$SCHEMA" use-system-font false 2>/dev/null; then
                    gsettings set "$SCHEMA" font 'JetBrainsMono Nerd Font Mono 12' 2>/dev/null
                    echo -e "${GREEN}✅ GNOME Terminal font updated automatically!${NC}"
                fi
            fi
        fi
    fi
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
