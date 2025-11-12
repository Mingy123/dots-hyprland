alias ls='ls --color=auto'
lst() {
    ls "$@" --color=always --time-style=long-iso -ltr | sed -E "s/^[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +//" | tail -n +2
}
lstb() {
    lst $@ | tail -n 20
}

alias gpp='g++'
alias sizeof='du -hsc'
alias sizes='du -hsc *|sort -h'
alias vi='vim'
alias bsf='base64'
alias sha='sha256sum'
alias dc='cd -'
alias rrf='rm -rf'
alias cat='bat --plain'
alias gdb='gdb -q'
alias windows='doas mount /dev/nvme0n1p3 /disk'
alias unwindows='doas umount /disk'

ytsearch() {
    local search_string="$1"
    shift
    local encoded_search_string=$(echo -n "$search_string" | jq -sRr @uri | sed 's/%20/+/g')
    local url="https://www.youtube.com/results?search_query=${encoded_search_string}"
    yt-dlp $@ --playlist-items 1:1 "$url"
}


# Luke's config for the Zoomer Shell
# Enable colors and change prompt:
autoload -U colors && colors
PS1="%B%{$fg[green]%}[%{$fg[yellow]%}%n%{$fg[red]%}@%{$fg[cyan]%}%M %{$fg[magenta]%}%1~%{$fg[green]%}]%{$reset_color%}%(!.#.$)%b "

# History in cache directory:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)

# vi mode
bindkey -v
export KEYTIMEOUT=1
# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

### changing cursor shape through vi mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q'
preexec() { echo -ne '\e[5 q' ;}

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
