# .zshrc by anton@dyingstar.net

# === ZSH Config ===
bindkey -e
export HOSTNAME=$(hostname)

if [[ -v NB_UMASK ]]; then
  umask $NB_UMASK
fi

ZSH_TAB_TITLE_PREFIX="$USER@$HOST "

# === Environment ===
if [[ -x $(which nvim) ]]; then
  export EDITOR="$(which nvim)"
  export VISUAL="$(which nvim)"
fi

EZA_ICON_SPACING=2

# === Aliases ===
alias ls='eza --color=always --icons=auto --group-directories-first' # just replace ls by exa and allow all other exa arguments
alias l='ls -lbF' #   list, size, type
alias ll='ls -laag' # long, all
alias lll='ls -laag | less'
alias llm='ll --sort=modified' # list, long, sort by modification date
alias la='ls -lbhHigUmuSa' # all list
alias lx='ls -lbhHigUmuSa@' # all list and extended
alias tree='eza --tree' # tree view
alias lS='eza -1' # one column by just names
alias less='less -R' # passthrough colors

alias tm='tmux new -A -s main'

# Prepend our local path
export PATH=$HOME/bin:$HOME/.local/bin:/opt/repo/bin:$PATH

# === History ===
HISTORY_BASE="${HOME}/.history/${USER}@${HOSTNAME}/"; export HISTORY_BASE
mkdir -p $HISTORY_BASE
HISTFILE="${HISTORY_BASE}/${USER}@${HOSTNAME}.history"; export HISTFILE
HISTSIZE=10000
SAVEHIST=100000000
HISTORY_START_WITH_GLOBAL=true

setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY_TIME

# === Antidote ===
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
antidote load

# === Zoxide ===
if [[ ! -f ~/.local/bin/zoxide ]]; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

eval "$(zoxide init zsh)"

alias ssh="TERM=xterm-256color ssh"
alias vim="nvim"

exa_ico=('--icons')
exa_params=(${exa_params:|exa_ico})

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# === Completion ===
zstyle :compinstall filename '$HOME/.zshrc'
autoload -Uz compinit
compinit

# Rust
if [ -f ${HOME}/.cargo/env ]; then
  . ${HOME}/.cargo/env
fi