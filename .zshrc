export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="delta"
export MANPAGER='sh -c "col -bx | bat -l man -p"'
export LESS="-R"

[[ -o interactive ]] || return 0

mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh"

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

autoload -Uz compinit
zmodload zsh/complist

_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-${HOST%%.*}-${ZSH_VERSION}"
if [[ -s "$_zcompdump" ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -i -d "$_zcompdump"
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-prompt '%S%M matches%s'
zstyle ':completion:*' select-prompt '%SScrolling active: %p%s'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' squeeze-slashes true

if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(@s/:/)LS_COLORS}"
fi

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
  alias find='fd'
fi

export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline-right
  --pointer=
  --marker=󰄬
  --prompt=  
  --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7
  --color=fg+:#c0caf5,bg+:#24283b,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#bb9af7,pointer:#f7768e
  --color=marker:#9ece6a,spinner:#7dcfff,header:#e0af68
'

plugins=(
  "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
  "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
  "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)

for plugin_path in "${plugins[@]}"; do
  [[ -f "$plugin_path" ]] && source "$plugin_path"
done

zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=~60% --layout=reverse --border=rounded --preview-window=right:55%:wrap
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=2 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:export:*' fzf-preview 'printenv ${(Q)word}'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -fp $word'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --decorate --color=always -n 25 -- $word'

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey '^[[Z' reverse-menu-complete

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

starship_transient_prompt_accept_line() {
  local saved_prompt="$PROMPT"
  local saved_rprompt="$RPROMPT"

  PROMPT="%F{#7aa2f7}❯%f "
  RPROMPT=""
  zle .reset-prompt
  zle .accept-line
  PROMPT="$saved_prompt"
  RPROMPT="$saved_rprompt"
}

zle -N starship_transient_prompt_accept_line
bindkey '^M' starship_transient_prompt_accept_line

alias ls='eza --icons=always --group-directories-first'
alias ll='eza -lah --icons=always --git'
alias la='eza -la --icons=always --group-directories-first'
alias lt='eza --tree --level=2 --icons=always'
alias grep='rg'
alias v='nvim'
alias g='git'
alias lg='lazygit'
alias c='clear'
alias ff='fastfetch'
alias y='yazi'
alias j='just'
alias ghv='gh repo view --web'
alias glog='git log --graph --oneline --decorate --all'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias py='uv run python'
alias pip='uv pip'
alias md='glow'
alias top='btop'

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --theme=tokyonight_night --style=plain'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --theme=tokyonight_night --style=plain'
fi

if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi
