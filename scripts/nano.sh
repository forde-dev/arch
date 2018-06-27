#!/usr/bin/env bash

# Load common functions
files=$(dirname $0)/files
source ${files}/support.sh

if [[ ! -r "/usr/bin/yay" ]]; then
    echo "Missing dependency: yay"
    exit 1
fi

sudo mkdir -p /root/.config/nano /etc/skel/.config/nano
pacman -Q nano-syntax-highlighting-git >/dev/null 2>&1
if [ $? != 0 ]; then
    yay -S --noconfirm nano-syntax-highlighting-git
fi

# Enable Support for All Highlighters and Disable text wraping
echo 'include "/usr/share/nano-syntax-highlighting/*.nanorc"' | sudo tee /root/.config/nano/nanorc >/dev/null
echo 'set nowrap' | sudo tee -a /root/.config/nano/nanorc >/dev/null
echo 'set autoindent' | sudo tee -a /root/.config/nano/nanorc >/dev/null
echo 'set boldtext' | sudo tee -a /root/.config/nano/nanorc >/dev/null
echo 'set linenumbers' | sudo tee -a /root/.config/nano/nanorc >/dev/null
echo 'set smooth' | sudo tee -a /root/.config/nano/nanorc >/dev/null
sudo cp /root/.config/nano/nanorc /etc/skel/.config/nano/nanorc

cpToUsers /root/.config/nano/nanorc .config/nano/nanorc
