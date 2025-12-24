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

configure_gnome_terminal() {
    if command -v gsettings &> /dev/null; then
        echo -e "${BLUE}⚙️  Configuring GNOME Terminal font...${NC}"
        # Get default profile ID, removing single quotes
        PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
        
        if [ -n "$PROFILE_ID" ]; then
            SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"
            
            # Disable system font usage
            if gsettings set "$SCHEMA" use-system-font false 2>/dev/null; then
                # Set the Nerd Font
                gsettings set "$SCHEMA" font 'JetBrainsMono Nerd Font Mono 12' 2>/dev/null
                echo -e "${GREEN}✅ GNOME Terminal font updated to JetBrainsMono Nerd Font!${NC}"
            else
                echo -e "${YELLOW}⚠️  Could not set GNOME Terminal settings (schema not found or DBus issue).${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Could not detect GNOME Terminal profile.${NC}"
        fi
    fi
}

install_nerd_fonts() {
    # Only for Linux in this script (macOS users usually install fonts manually or via cask)
    if [ "$OS" != "Linux" ]; then return; fi

    if fc-list : family=JetBrainsMono | grep -q "Nerd Font"; then
        echo -e "${GREEN}✅ JetBrainsMono Nerd Font is already installed.${NC}"
    else
        echo -e "${BLUE}🔤 Installing JetBrainsMono Nerd Font...${NC}"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
        FONT_DIR="/usr/local/share/fonts/JetBrainsMonoNerd"
        
        $SUDO mkdir -p "$FONT_DIR"
        
        TMP_DIR=$(mktemp -d)
        wget -q --show-progress -O "$TMP_DIR/font.zip" "$FONT_URL"
        unzip -q "$TMP_DIR/font.zip" -d "$TMP_DIR"
        
        $SUDO mv "$TMP_DIR/"*.ttf "$FONT_DIR/"
        $SUDO fc-cache -fv > /dev/null
        
        rm -rf "$TMP_DIR"
        echo -e "${GREEN}✅ Nerd Font installed!${NC}"
    fi
    
    # Try to auto-configure terminal if possible
    configure_gnome_terminal
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
                $SUDO apt-get install -y git zsh curl wget fzf ripgrep tmux tree unzip fontconfig
                
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
                                     # Find the binary regardless of directory structure
                                     FOUND_BIN=$(find "$TMP_DIR" -type f -name "eza" | head -n 1)
                                     if [ -n "$FOUND_BIN" ]; then
                                         $SUDO mv "$FOUND_BIN" /usr/local/bin/eza
                                         $SUDO chmod +x /usr/local/bin/eza
                                         echo "Eza installed from binary."
                                     else
                                          echo "Extracted tarball but could not find 'eza' binary."
                                     fi
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
                
                # Nerd Fonts
                install_nerd_fonts
                ;;

            fedora|rhel|centos)
                $SUDO dnf install -y git zsh curl wget fzf ripgrep bat eza zoxide tmux tree unzip fontconfig
                install_starship_manual
                install_nerd_fonts
                ;;

            arch|manjaro|endeavouros)
                $SUDO pacman -Sy --noconfirm git zsh curl wget fzf ripgrep bat eza zoxide starship tmux tree unzip fontconfig
                install_nerd_fonts
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

if [ -n "$ZSH_PATH" ]; then
    # Ensure Zsh is in /etc/shells (Linux only usually)
    if [ "$OS" = "Linux" ] && ! grep -q "$ZSH_PATH" /etc/shells; then
        echo -e "${YELLOW}Adding $ZSH_PATH to /etc/shells...${NC}"
        echo "$ZSH_PATH" | $SUDO tee -a /etc/shells > /dev/null
    fi

    if [ "$CURRENT_SHELL" != "zsh" ]; then
        echo -e "${YELLOW}Switching default shell to Zsh...${NC}"
        
        # Try changing shell
        if $SUDO -v &> /dev/null; then
             $SUDO chsh -s "$ZSH_PATH" "$USER"
        else
             chsh -s "$ZSH_PATH"
        fi
        
        # Verify change
        NEW_SHELL=$(getent passwd "$USER" | cut -d: -f7)
        if [ "$NEW_SHELL" = "$ZSH_PATH" ]; then
            echo -e "${GREEN}✅ Shell permanently changed to Zsh.${NC}"
        else
            echo -e "${RED}❌ Shell change failed. Current shell in /etc/passwd: $NEW_SHELL${NC}"
            echo -e "${YELLOW}Please run 'chsh -s $(which zsh)' manually.${NC}"
        fi
    else
        echo -e "${GREEN}✅ You are already using Zsh.${NC}"
    fi
else
    echo -e "${RED}❌ Zsh not found! Please install zsh manually.${NC}"
fi

# ... (Font configuration) ...

configure_gnome_terminal() {
    if command -v gsettings &> /dev/null; then
        echo -e "${BLUE}⚙️  Configuring GNOME Terminal font...${NC}"
        
        # Ensure DBus session is accessible
        if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
        fi

        # Find the exact installed Nerd Font name (prefer Mono)
        N_FONT=$(fc-list : family | grep "JetBrainsMono Nerd Font Mono" | head -n 1 | cut -d',' -f1)
        if [ -z "$N_FONT" ]; then
            N_FONT=$(fc-list : family | grep "JetBrainsMono Nerd Font" | head -n 1 | cut -d',' -f1)
        fi

        if [ -n "$N_FONT" ]; then
            echo "   Found font: $N_FONT"
            PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
            
            if [ -n "$PROFILE_ID" ]; then
                SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"
                
                # Disable system font usage
                if gsettings set "$SCHEMA" use-system-font false 2>/dev/null; then
                    # Set the Nerd Font
                    gsettings set "$SCHEMA" font "$N_FONT 12" 2>/dev/null
                    echo -e "${GREEN}✅ GNOME Terminal font updated to '$N_FONT 12'!${NC}"
                else
                    echo -e "${YELLOW}⚠️  Could not set GNOME Terminal settings. (Try running locally, not via SSH)${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  JetBrainsMono Nerd Font not detected in fc-list.${NC}"
        fi
    fi
}