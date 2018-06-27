#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Color PS1 Promt as green for normal user
PS1="\[\033[38;5;10m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]: \[$(tput sgr0)\]\[\033[38;5;6m\][\w]\[$(tput sgr0)\]\[\033[38;5;10m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

# ------------------------------
# Functions
# ------------------------------

# Color man pages with green for normal user
man() {
    env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;36m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

# ------------------------------
# Aliases
# ------------------------------

# Pacman aliases
alias sudo='sudo '
alias pacrm='sudo /usr/bin/pacman -Rs'
alias pacup='sudo /usr/bin/pacman -Syu'
alias pacin='sudo /usr/bin/pacman --needed -Sy'
