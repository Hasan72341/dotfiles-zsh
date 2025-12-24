# Plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Starship
eval "$(starship init zsh)"

# ─────────────────────────────────────────
# TRANSIENT PROMPT
# ─────────────────────────────────────────
starship-transient-prompt-accept-line() {
  # Save original prompts
  local saved_prompt="$PROMPT"
  local saved_rprompt="$RPROMPT"

  # Set transient appearance
  PROMPT="%F{#7aa2f7}❯ %f"
  RPROMPT=""
  zle .reset-prompt
  
  # Execute the command
  zle .accept-line

  # Restore originals (so Starship knows the 'real' context for next time)
  PROMPT="$saved_prompt"
  RPROMPT="$saved_rprompt"
}

# Register the widget and bind it to Enter
zle -N starship-transient-prompt-accept-line
bindkey '^M' starship-transient-prompt-accept-line

# History
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups

# Navigation
eval "$(zoxide init zsh --cmd cd)"

# FZF
eval "$(fzf --zsh)"

# TokyoNight-friendly aliases
alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --git"
if command -v bat &> /dev/null; then
    alias cat="bat --theme=tokyonight"
elif command -v batcat &> /dev/null; then
    alias cat="batcat --theme=tokyonight"
fi
alias grep="rg"