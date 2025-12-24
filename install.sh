#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Cross-Platform Setup...${NC}"

# ─────────────────────────────────────────────────────────────────────────────
# 1. OS & Distro Detection
# ─────────────────────────────────────────────────────────────────────────────
OS="$(uname -s)"
DISTRO=""
SUDO=""

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo -e "${RED}❌ Root privileges required but 'sudo' not found.${NC}"
        exit 1
    fi
fi

if [ "$OS" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    echo -e "${GREEN}🐧 Detected Linux ($DISTRO)${NC}"
elif [ "$OS" = "Darwin" ]; then
    echo -e "${GREEN}🍎 Detected macOS${NC}"
else
    echo -e "${RED}❌ Unsupported OS: $OS${NC}"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. Package Manager Selection & Installation
# ─────────────────────────────────────────────────────────────────────────────

install_starship_manual() {
    if ! command -v starship &> /dev/null; then
        echo -e "${YELLOW}⭐ Installing Starship via script...${NC}"
        sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
    fi
}

install_packages() {
    echo -e "${BLUE}📦 Installing packages...${NC}"
    
    if [ "$OS" = "Darwin" ]; then
        # macOS (Homebrew)
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}🍺 Installing Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to path for immediate use
            if [ -f /opt/homebrew/bin/brew ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -f /usr/local/bin/brew ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        brew install starship zoxide fzf eza bat ripgrep git wget curl tmux tree

    elif [ "$OS" = "Linux" ]; then
        case "$DISTRO" in
            ubuntu|debian|pop|kali|linuxmint)
                # Remove potentially broken eza repo source from previous runs to prevent apt-get update failure
                if [ -f /etc/apt/sources.list.d/gierens.list ]; then
                    echo "Removing existing gierens.list to ensure clean setup..."
                    $SUDO rm -f /etc/apt/sources.list.d/gierens.list
                fi
                
                $SUDO apt-get update
                # bat is often 'bat' or 'batcat', eza needs external repo or manual
                # Install basics
                $SUDO apt-get install -y git zsh curl wget fzf ripgrep tmux tree
                
                # Install Bat (batcat)
                $SUDO apt-get install -y bat
                # Make a symlink for bat if it's installed as batcat
                if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
                    mkdir -p ~/.local/bin
                    ln -s $(which batcat) ~/.local/bin/bat
                    export PATH="$HOME/.local/bin:$PATH"
                fi

                # Install Eza (modern ls) - requires gpg setup usually, or cargo
                # Attempting cargo if rust is there, or simple apt if available in newer versions
                # For stability, we'll try to get it via official means or cargo
                if ! command -v eza &> /dev/null; then
                     echo "Installing eza..."
                     # Check if we can use cargo
                     if command -v cargo &> /dev/null; then
                         echo "Installing eza via Cargo..."
                         cargo install eza
                     else
                         echo "Attempting to install eza via apt..."
                         $SUDO mkdir -p /etc/apt/keyrings
                         wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
                         echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO tee /etc/apt/sources.list.d/gierens.list
                         $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                         
                         if $SUDO apt-get update && $SUDO apt-get install -y eza; then
                             echo "Eza installed successfully via apt."
                         else
                             echo "Apt installation failed. Falling back to binary download..."
                             # Clean up potential broken list file to avoid future apt errors
                             $SUDO rm -f /etc/apt/sources.list.d/gierens.list
                             
                             ARCH=$(uname -m)
                             EZA_URL=""
                             if [ "$ARCH" = "x86_64" ]; then
                                 EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                             elif [ "$ARCH" = "aarch64" ]; then
                                 EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz"
                             fi

                             if [ -n "$EZA_URL" ]; then
                                 TMP_DIR=$(mktemp -d)
                                 echo "Downloading $EZA_URL..."
                                 if curl -L "$EZA_URL" | tar xz -C "$TMP_DIR"; then
                                     $SUDO mv "$TMP_DIR/eza" /usr/local/bin/eza
                                     $SUDO chmod +x /usr/local/bin/eza
                                     echo "Eza installed from binary."
                                 else
                                     echo "Failed to download/extract eza binary."
                                 fi
                                 rm -rf "$TMP_DIR"
                             else
                                 echo "Architecture $ARCH not supported for automatic binary install."
                             fi
                         fi
                     fi
                fi

                # Install Zoxide
                if ! command -v zoxide &> /dev/null; then
                    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                fi
                
                # Starship
                install_starship_manual
                ;;

            fedora|rhel|centos)
                $SUDO dnf install -y git zsh curl wget fzf ripgrep bat eza zoxide tmux tree
                install_starship_manual
                ;;

            arch|manjaro|endeavouros)
                $SUDO pacman -Sy --noconfirm git zsh curl wget fzf ripgrep bat eza zoxide starship tmux tree
                ;;

            *)
                echo -e "${YELLOW}⚠️ Unknown Linux distro: $DISTRO. Attempting generic install...${NC}"
                # Generic fallback using Cargo if available, or just warning
                if command -v cargo &> /dev/null; then
                    cargo install starship zoxide eza bat ripgrep-all
                else
                    echo -e "${RED}Please install: git zsh starship zoxide fzf eza bat ripgrep manually.${NC}"
                fi
                ;;
        esac
    fi
}

install_packages

# ─────────────────────────────────────────────────────────────────────────────
# 3. Setup Zsh Plugins
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}🔌 Setting up Zsh plugins...${NC}"
PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

clone_or_update() {
    local repo_url=$1
    local dest_dir=$2
    if [ -d "$dest_dir" ]; then
        # echo "   Updating $(basename "$dest_dir")..."
        (cd "$dest_dir" && git pull --quiet)
    else
        echo "   Cloning $(basename "$dest_dir")..."
        git clone --quiet "$repo_url" "$dest_dir"
    fi
}

clone_or_update "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting" "$PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_update "https://github.com/zsh-users/zsh-history-substring-search" "$PLUGIN_DIR/zsh-history-substring-search"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Setup Bat Theme
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}🦇 Setting up Bat theme (Tokyo Night)...${NC}"
BAT_CMD="bat"
if command -v batcat &> /dev/null; then BAT_CMD="batcat"; fi

if command -v $BAT_CMD &> /dev/null; then
    BAT_CONFIG_DIR="$($BAT_CMD --config-dir)"
    mkdir -p "$BAT_CONFIG_DIR/themes"
    curl -sL "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme" -o "$BAT_CONFIG_DIR/themes/tokyonight.tmTheme"
    $BAT_CMD cache --build > /dev/null
else
    echo -e "${YELLOW}⚠️ Bat not found, skipping theme setup.${NC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Copy Configurations
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}📁 Copying configurations...${NC}"
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

copy_file() {
    local src=$1
    local dest=$2
    
    mkdir -p "$(dirname "$dest")"
    
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        # Backup existing
        mv "$dest" "$dest.bak.$(date +%s)"
    fi
    cp "$src" "$dest"
    echo "   Copied $src -> $dest"
}

copy_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
copy_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# ─────────────────────────────────────────────────────────────────────────────
# 6. Silence Terminal Startup
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}🤫 Silencing 'Last login' message...${NC}"
touch "$HOME/.hushlogin"


# ─────────────────────────────────────────────────────────────────────────────
# 7. Switch to Zsh
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}🐚 Checking shell...${NC}"
CURRENT_SHELL=$(basename "$SHELL")

if [ "$OS" = "Darwin" ]; then
    ZSH_PATH="/bin/zsh"
else
    ZSH_PATH=$(which zsh)
fi

if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo -e "${YELLOW}Switching default shell to Zsh...${NC}"
    if [ -n "$ZSH_PATH" ]; then
        # Try changing shell
        if $SUDO -v &> /dev/null; then
             # If we have sudo, use it to change safely
             $SUDO chsh -s "$ZSH_PATH" "$USER"
        else
             chsh -s "$ZSH_PATH"
        fi
        
        echo -e "${GREEN}✅ Shell changed to Zsh! Please log out and back in.${NC}"
    else
        echo -e "${RED}❌ Zsh not found! Please install zsh manually.${NC}"
    fi
else
    echo -e "${GREEN}✅ You are already using Zsh.${NC}"
fi

echo -e "${GREEN}✨ Setup complete!${NC}"
echo -e "If the prompt doesn't look right, ensure you have a Nerd Font installed."

# Automatically switch to zsh
if [ -n "$ZSH_PATH" ]; then
    echo -e "${BLUE}🔄 Switching to Zsh now...${NC}"
    exec "$ZSH_PATH" -l
fi