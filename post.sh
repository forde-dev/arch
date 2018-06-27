#!/usr/bin/env bash
set -e
set -u

# Locale Settings
locale-gen
hwclock --systohc

echo "Optimizing Pacman Database"
pacman-key --populate archlinux
pacman-key --init
#pacman-optimize

# Update mlocate database if installed
if [ -f "/usr/bin/updatedb" ]; then
    echo "Updating mlocate database"
	updatedb
fi

# Update pkgfile database if installed
if [ -f "/usr/bin/pkgfile" ]; then
    echo "Updating pkgfile database"
	pkgfile --update
fi

# Changeing Pacman Configuration to add colored output
sed -i 's/#Color/Color/' /etc/pacman.conf

# Create 'arch-release' if runing under vmware
if [ $(systemd-detect-virt) == "vmware" ]; then
    cat /proc/version > /etc/arch-release
fi

# Create important directorys
mkdir -p /root/.config/
mkdir -p /etc/skel/.config/


###################
## User Accounts ##
###################

ROOTPASSWORD=$1
USERNAME=$2
USERPASS=$3

echo "Changing Root password"
echo -e "${ROOTPASSWORD}\n${ROOTPASSWORD}" | passwd root

# Create user acount
useradd -m -G wheel,users -s /bin/bash ${USERNAME}
echo -e "${USERPASS}\n${USERPASS}" | passwd ${USERNAME}

# Change sudoers to allow wheel group access to sudo with password
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/10_wheel
chmod 640 /etc/sudoers.d/10_wheel


##################
## Pacman Hooks ##
##################

# Create any missing directories
mkdir -p /etc/pacman.d/hooks

# Update rEFInd boot files on refind-efi
cat > /etc/pacman.d/hooks/refind.hook <<EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = refind-efi
[Action]
Description = Updating rEFInd on ESP...
When=PostTransaction
Exec=/usr/bin/refind-install
EOF

# Keep currently installed & the last 2 cached
if [ -f "/usr/bin/paccache" ]; then
cat > /etc/pacman.d/hooks/paccache.hook <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = *
[Action]
Description = Keep currently installed & the last 2 cached...
When = PostTransaction
Exec = /usr/bin/paccache -rv
EOF
fi

# Update pacman-mirrorlist on upgrade
if [ -f "/usr/bin/reflector" ]; then
cat > /etc/pacman.d/hooks/mirrorupgrade.hook <<EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist
[Action]
Description = Updating pacman-mirrorlist with reflector...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "reflector --country 'Ireland' --country 'United Kingdom' --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist;  rm -f /etc/pacman.d/mirrorlist.pacnew"
EOF
fi


################
## Aur Helper ##
################

# Change sudoers to allow nobody user access to sudo without password
echo 'nobody ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99_nobody

# Create Build Directorys and set permissions
mkdir /tmp/build
chgrp nobody /tmp/build
chmod g+ws /tmp/build
setfacl -m u::rwx,g::rwx /tmp/build
setfacl -d --set u::rwx,g::rwx,o::- /tmp/build
cd /tmp/build/

# Install Yay AUR Helper
sudo -u nobody curl -SLO https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
sudo -u nobody tar -zxvf yay.tar.gz
cd yay
sudo -u nobody makepkg -s -i --noconfirm
cd ../..
rm -r build

# Change sudoers to allow wheel group access to sudo with password
rm /etc/sudoers.d/99_nobody
