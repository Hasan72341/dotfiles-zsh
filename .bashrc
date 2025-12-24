# ─────────────────────────────────────────
# STARSHIP
# ─────────────────────────────────────────
eval "$(starship init bash)"

# ─────────────────────────────────────────
# HISTORY
# ─────────────────────────────────────────
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth:erasedups

# ─────────────────────────────────────────
# NAVIGATION
# ─────────────────────────────────────────
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# ─────────────────────────────────────────
# FZF
# ─────────────────────────────────────────
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ─────────────────────────────────────────
# ALIASES
# ─────────────────────────────────────────
if command -v eza &> /dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lah --git"
else
    alias ls="ls --color=auto"
    alias ll="ls -lah"
fi

alias grep="rg"

if command -v bat &> /dev/null; then
    alias cat="bat --theme=tokyonight"
elif command -v batcat &> /dev/null; then
    alias cat="batcat --theme=tokyonight"
fi

# ─────────────────────────────────────────
# PATH
# ─────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
