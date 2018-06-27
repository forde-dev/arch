#!/usr/bin/env bash

# This script will install zsh & oh-my-zsh to make configuring zsh easier
# Also adds a pre-configured .zshrc file for all users

# This script will only run when running as a normal user
if [[ $EUID == 0 ]]; then
    echo "This script must be run as a normal user."
    exit 1
elif [[ ! -r "/usr/bin/yay" ]]; then
    echo "Missing dependency: yay"
    exit 1
fi

files=$(dirname $0)/files
source ${files}/support.sh

# Install zsh & zsh extras
sudo pacman -S --noconfirm --needed zsh zsh-syntax-highlighting zsh-theme-powerlevel9k pkgfile
pacman -Q oh-my-zsh-git >/dev/null 2>&1
if [ $? != 0 ]; then
    yay -S --noconfirm oh-my-zsh-git
fi

pacman -Q nerd-fonts-complete >/dev/null 2>&1
if [ $? != 0 ]; then
    yay -S --noconfirm nerd-fonts-complete
fi

# Install 'powerline-fonts' from community repo after a new release, v2.7 or greater
pacman -Q powerline-fonts-git >/dev/null 2>&1
if [ $? != 0 ]; then
    yay -S --noconfirm --asdeps powerline-fonts-git
fi

# Enable pkgfile timer to update db
sudo systemctl enable pkgfile-update.timer

# Add zsh-syntax-highlighting & powerlevel9K to oh-my-zsh
if [[ ! -d "/usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
    sudo ln -s /usr/share/zsh/plugins/zsh-syntax-highlighting/ /usr/share/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

if [[ ! -d "/usr/share/oh-my-zsh/custom/themes/powerlevel9k" ]]; then
    sudo ln -s /usr/share/zsh-theme-powerlevel9k /usr/share/oh-my-zsh/custom/themes/powerlevel9k
fi

# Install all the zshrc files
sudo install -vm 644 ${files}/dotzshrc /etc/skel/.zshrc
sudo install -vm 644 ${files}/dotzshrc /root/.zshrc
cpToUsers ${files}/dotzshrc .zshrc

# Change current users shell to ZSH
if [ ! $(chkShell "${USER}") == "/bin/zsh" ]; then
    chsh -s /bin/zsh
    echo "Please logout and login again for changes to take effect"
fi
