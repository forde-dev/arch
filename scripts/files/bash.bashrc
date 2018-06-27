#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $DISPLAY ]] && shopt -s checkwinsize

case ${TERM} in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'

    ;;
  screen*)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
    ;;
esac

# ------------------------------
# Functions
# ------------------------------

# Color man pages with red for root user
# Color codes (https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

# ------------------------------
# User Configuration
# ------------------------------

# Try to enable the auto-completion (type: "pacman -S bash-completion" to install it).
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# Try to enable the "Command not found" hook ("pacman -S pkgfile" to install it).
[ -r /usr/share/doc/pkgfile/command-not-found.bash ] && . /usr/share/doc/pkgfile/command-not-found.bash

# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when it regains control.
shopt -s checkwinsize

# Enable history appending instead of overwriting.
shopt -s histappend

# Color PS1 Promt as red for root
PS1="\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]: \[$(tput sgr0)\]\[\033[38;5;6m\][\w]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

# Set prompts
PS2='> '
PS3='> '
PS4='+ '

# ------------------------------
# Aliases
# ------------------------------

# Colorize common commands
alias ls='ls --color=auto'
alias dmesg='dmesg --color=auto'
alias dir='dir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# Pacman aliases
alias pacin="/usr/bin/pacman --needed -Sy"
alias pacup="/usr/bin/pacman -Syu"
alias pacrm="/usr/bin/pacman -Rs"
alias pacinfo="/usr/bin/pacman -Si"

# Protection aliases
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
alias su='su -'

# Show hidden files without directory markers but with
# leading backslashes and human readable file sizes
alias la='ls -hAlF'

# Sort ls shortcuts
alias lx='ls -lhXBF' # sort by extension
alias lk='ls -lhSrF' # sort by size
alias lt='ls -lhtrF' # sort by date

# Disk free in human terms
alias df='df -h'

# Extras
alias untar='tar -xvf'

# ------------------------------
# Misc
# ------------------------------

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Replace VI with nano as the default text editor
export VISUAL=nano
export EDITOR=nano
