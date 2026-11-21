# History
HISTSIZE=100000
SAVEHIST=1000000
HISTFILE=~/.zsh_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups

# Alias
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias opencode='opencode --auto'
alias vim='nvim'

# Env
export EDITOR=vim
export WORDCHARS='*?_.[]~-=&;!#$%^(){}<>'
export PATH="$PATH:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt no_flow_control
setopt extended_glob
setopt menu_complete
setopt nonomatch
setopt correct
setopt list_packed
setopt magic_equal_subst

# Extra shell snippets (shortcuts.zsh, generated terminal colors) and, on
# NixOS, the store paths the .zshrc itself cannot know about
# (modules/home-manager/zsh.nix → zshrc.d/10-nix-plugins.zsh). Sourced before compinit so
# drop-ins can extend the completion setup.
for f in ~/.config/zshrc.d/*.zsh(N) ~/.config/zshrc.d/*.sh(N); do
    source "$f"
done

# Outside NixOS, load plugins with a manual antidote install in ~/.antidote
# or ~/.local/share/antidote using ~/.zsh_plugins.txt. NixOS instead sources
# flake-pinned nixpkgs plugins from the drop-in above.
#
# Loaded before compinit so kind:fpath plugins (zsh-completions) land in
# $fpath in time. Plugins that must run after compinit are marked kind:defer
# in the list (zsh-syntax-highlighting) and are sourced at the first prompt.
if [[ -z ${DOTFILES_NIX_ZSH_HIGHLIGHT:-} ]]; then
for antidote_zsh in "${ANTIDOTE_ZSH_FILE:-$HOME/.antidote/antidote.zsh}" "$HOME/.local/share/antidote/antidote.zsh"; do
    [[ -r "$antidote_zsh" ]] || continue
    source "$antidote_zsh"
    [[ -r "$HOME/.zsh_plugins.txt" ]] && antidote load "$HOME/.zsh_plugins.txt"
    break
done
unset antidote_zsh
fi

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' list-colors "${LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:manuals' separate-sections true

# VCS info
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{yellow}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
PROMPT='%F{magenta}%B%n%b%f@%F{blue}%U${CONTAINER_ID:-%m}%u%f:%F{green}%1~%f%F{cyan}$vcs_info_msg_0_%f%F{white}$%f '

# Key bindings
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[2~' overwrite-mode
bindkey '^[[5~' history-search-backward
bindkey '^[[6~' history-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# terminfo
if [[ "${terminfo[kdch1]}" != "" ]]; then bindkey "${terminfo[kdch1]}" delete-char; fi
if [[ "${terminfo[khome]}" != "" ]]; then bindkey "${terminfo[khome]}" beginning-of-line; fi
if [[ "${terminfo[kend]}"  != "" ]]; then bindkey "${terminfo[kend]}"  end-of-line; fi

# Bitwarden SSH agent. Native install (nixpkgs bitwarden-desktop) uses the
# home-directory socket; the flatpak path is kept as a fallback.
if [[ -S "$HOME/.bitwarden-ssh-agent.sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
elif [[ -S "$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
fi

# android-develop-tools
if [ -d "$HOME/platform-tools" ] ; then
    PATH="$HOME/platform-tools:$PATH"
fi

# set PATH so it includes users private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [[ -n ${DOTFILES_NIX_ZSH_HIGHLIGHT:-} ]]; then
    source "$DOTFILES_NIX_ZSH_HIGHLIGHT"
fi
