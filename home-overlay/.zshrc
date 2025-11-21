# .zshrc by anton@bnext.bio

# === ZSH Config ===
bindkey -e
export HOSTNAME=$(hostname)

if [[ -v NB_UMASK ]]; then
  umask $NB_UMASK
fi

ZSH_TAB_TITLE_PREFIX="$USER@$HOST "

# === Antidote Plugins ===
source /opt/antidote/antidote.zsh
antidote load

# === Environment ===
if [[ -x $(which nvim) ]]; then
  export EDITOR="$(which nvim)"
  export VISUAL="$(which nvim)"
  alias vim='nvim'
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

# === Tools Setup ===
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# === Conda ===
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/conda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<