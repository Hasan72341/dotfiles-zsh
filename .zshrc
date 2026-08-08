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
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin"

[[ -o interactive ]] || return 0

# Local secrets (not tracked in git)
[[ -f "$HOME/.zsh/secrets.zsh" ]] && source "$HOME/.zsh/secrets.zsh"

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
# Disabled 'completion' strategy to fix: "can't open pseudo terminal: device not configured"
ZSH_AUTOSUGGEST_STRATEGY=(history)

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

if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
  eval "$("$HOME/miniconda3/bin/conda" shell.zsh hook)"
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
alias j='just'
alias ghv='gh repo view --web'
alias glog='git log --graph --oneline --decorate --all'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias md='glow'
alias top='btop'
#alias claude="ANTHROPIC_AUTH_TOKEN="freecc" ANTHROPIC_BASE_URL="http://localhost:8082" CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 claude --dangerously-skip-permissions"
alias litellm-proxy="litellm --config ~/litellm-config.yaml --port 4000"


if command -v bat >/dev/null 2>&1; then
  alias cat='bat --theme=tokyonight --style=plain'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --theme=tokyonight --style=plain'
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

# Added by Antigravity
export PATH="/Users/hasanraza/.antigravity/antigravity/bin:$PATH"

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
export MAMBA_EXE='/Users/hasanraza/.local/bin/micromamba';
export MAMBA_ROOT_PREFIX='/Users/hasanraza/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from micromamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/hasanraza/.lmstudio/bin"
# End of LM Studio CLI section

# Created by `pipx` on 2026-04-21 20:36:03
export PATH="$PATH:/Users/hasanraza/Library/Python/3.12/bin"

export PATH="/Users/hasanraza/.local/bin:$PATH"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator

# opencode
export PATH=/Users/hasanraza/.opencode/bin:$PATH
export PATH="/Applications/MATLAB_R2026a.app/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PYTHON=/opt/homebrew/bin/python3.12
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Added by Antigravity IDE
export PATH="/Users/hasanraza/.antigravity-ide/antigravity-ide/bin:$PATH"
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_API_KEY
unset ANTHROPIC_MODEL



alias apple="/Users/hasanraza/bin/ai-process"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/hasanraza/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/hasanraza/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/hasanraza/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/hasanraza/google-cloud-sdk/completion.zsh.inc'; fi

# bun completions
[ -s "/Users/hasanraza/.bun/_bun" ] && source "/Users/hasanraza/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/Users/hasanraza/.steel/bin:$PATH"

# >>> steel completions >>>
fpath=("$HOME/.zsh/completions" $fpath)
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit -C; }
# <<< steel completions <<<


# vm-input: (re)start the web interface (kills any running instance first)
alias vm-input-web='/Users/hasanraza/Documents/vm-input/bin/vm-input-web'
alias vm-input-tunnel='/Users/hasanraza/Documents/vm-input/bin/vm-input-tunnel'
alias vm-input='/Users/hasanraza/Documents/vm-input/bin/vm-input'

# Alias for using Claude Code with DeepSeek API
alias deepclaude='ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" ANTHROPIC_API_KEY="$DEEPSEEK_API_KEY" claude --model deepseek-v4-pro --dangerously-skip-permissions'


# ─── Nyora source-switch flippers ──────────────────────────────────────────
#   switch-a [on|off]   flip the ANDROID source switch   (no arg = toggle)
#   switch-w [on|off]   flip the WINDOWS source switch    (no arg = toggle)
# Handles the gh Hasan72341 account (and restores yours), waits for the CI
# flip + GitHub Pages/CDN to go live, and shows a progress bar.

_nyora_state() {   # echo true|false for a live signed config url
  curl -s "$1?cb=$(date +%s%N)" 2>/dev/null | \
    python3 -c "import sys,json,base64; print(str(json.loads(base64.b64decode(json.load(sys.stdin)['data'])).get('enabled')).lower())" 2>/dev/null
}

_nyora_bar() {   # $1 pct  $2 label
  local pct=$1 label=$2 w=28 i filled=$(( $1 * 28 / 100 ))
  printf '\r  \033[36m%-8s\033[0m [' "$label"
  for ((i=0; i<w; i++)); do (( i < filled )) && printf '█' || printf '░'; done
  printf '] %3d%%' "$pct"
}

_nyora_want() {   # $1 arg  $2 url  ->  true|false  ('' on bad arg)
  case "$1" in
    on|ON|true|1)    echo true ;;
    off|OFF|false|0) echo false ;;
    "")              [[ "$(_nyora_state "$2")" == true ]] && echo false || echo true ;;
    *)               echo "" ;;
  esac
}

_nyora_flip() {   # $1 repo  $2 configpath  $3 want(true/false)  $4 name
  local repo=$1 cfg=$2 want=$3 name=$4
  local url="https://hasan72341.github.io/${cfg}"
  local prev; prev=$(gh api user -q .login 2>/dev/null)
  _nyora_bar 5 "$name"
  gh auth switch --user Hasan72341 >/dev/null 2>&1
  if ! gh workflow run flip-switch.yml -R "Hasan72341/${repo}" -f enabled="${want}" >/dev/null 2>&1; then
    printf '\n  \033[31m✗\033[0m could not trigger the flip workflow\n'
    [[ -n $prev ]] && gh auth switch --user "$prev" >/dev/null 2>&1
    return 1
  fi
  local id="" t=0
  while [[ -z $id && $t -lt 20 ]]; do
    id=$(gh run list -R "Hasan72341/${repo}" --workflow=flip-switch.yml -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null)
    _nyora_bar 10 "$name"; sleep 1; (( t++ ))
  done
  local p=12
  while [[ "$(gh run view "$id" -R "Hasan72341/${repo}" --json status -q .status 2>/dev/null)" != completed ]]; do
    (( p < 50 )) && (( p += 4 )); _nyora_bar $p "$name"; sleep 2
  done
  local live="" q=55 tries=0
  while [[ "$live" != "$want" && $tries -lt 30 ]]; do
    live=$(_nyora_state "$url")
    [[ "$live" == "$want" ]] && break
    (( q < 97 )) && (( q += 3 )); _nyora_bar $q "$name"; sleep 3; (( tries++ ))
  done
  [[ -n $prev ]] && gh auth switch --user "$prev" >/dev/null 2>&1
  if [[ "$live" == "$want" ]]; then
    _nyora_bar 100 "$name"
    printf '\n  \033[32m✓\033[0m %s sources %s (live)\n' "$name" "$([[ $want == true ]] && echo ON || echo OFF)"
  else
    printf '\n  \033[33m⚠\033[0m %s: CI done but live still shows "%s" — CDN lag, recheck in ~1 min\n' "$name" "${live:-?}"
  fi
}

switch-a() {   # Android
  local url="https://hasan72341.github.io/nyora-android-switch/android-config.json"
  local w; w=$(_nyora_want "$1" "$url")
  [[ -z $w ]] && { echo "usage: switch-a [on|off]   (no arg = toggle current state)"; return 1; }
  _nyora_flip nyora-android-switch "nyora-android-switch/android-config.json" "$w" android
}

switch-w() {   # Windows
  local url="https://hasan72341.github.io/nyora-windows-parser/config.json"
  local w; w=$(_nyora_want "$1" "$url")
  [[ -z $w ]] && { echo "usage: switch-w [on|off]   (no arg = toggle current state)"; return 1; }
  _nyora_flip nyora-windows-parser "nyora-windows-parser/config.json" "$w" windows
}
# ─── end Nyora source-switch flippers ───────────────────────────────────────

# Add ~/bin to PATH (institute-vpn and other personal scripts)
export PATH="$HOME/bin:$PATH"

# kimi-code
export PATH="/Users/hasanraza/.kimi-code/bin:$PATH"

# NYORA_GLUON_GRAALVM — Gluon GraalVM for the on-device iOS parser engine
export GRAALVM_HOME="/Users/hasanraza/.gluon/graalvm/graalvm-java23-darwin-aarch64-gluon-23+25.1-dev/Contents/Home"
