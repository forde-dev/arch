#!/usr/bin/env bash

set -e
set -u

# check if system is uefi
if [ ! -d "/sys/firmware/efi/" ]; then
	echo "This script only works in UEFI"
	exit 1
fi

echo
echo
echo
echo "    WELCOME TO MY ARCH AUTOMATED INSTALLER"
echo
echo "  If you have issues email me at michael@fordetek.ie or fordetek@gmail.com"
echo "	WARNING, THIS WILL WIPE YOUR /dev/sda"
echo
echo
echo
echo
echo
echo
echo
echo

ROOTPASSWORD=""
CRPW=""

# replace rootpassword with the password you want to use and comment out the read line
#ROOTPASSWORD="rootpassword"
echo "  ~Setup the ROOT password~"
echo
read -s -p "Enter a Root Password: " ROOTPASSWORD
# CRPW = Comfirm Root PassWord
echo
read -s -p "Comfirm a Root Password: " CRPW

while [ "$ROOTPASSWORD" != "$CRPW" ] || [ "$ROOTPASSWORD" == "" ];
do
    echo
    echo
    echo "  Please try again, Passwords dident match"
    echo
    read -s -p "Password: " ROOTPASSWORD
    echo
    read -s -p "Password (again): " CRPW
done

USERNAME=""
# replace forde with the username you want to use and comment out the read line
#USERNAME="forde"
echo
echo
echo
echo
echo
echo "  ~Setup your User~"
echo
read -p "Enter a Username: " USERNAME

USERPASSWORD=""
CPW=""
# most important to change
#USERPASSWORD="password"
echo
echo
echo "  ~Setup password for user~"
echo
read -s -p "Enter a Password for your user: " USERPASSWORD
echo
read -s -p "Comfirm a Password for your user: " CPW

while [ "$USERPASSWORD" != "$CPW" ] || [ "$USERPASSWORD" == "" ];
do
    echo
    echo
    echo "  Please try again"
    echo
    read -s -p "Password: " USERPASSWORD
    echo
    read -s -p "Password (again): " CPW
done

HOSTNAME=""
# replace arch with the hostname you want to have and comment out the read line
#HOSTNAME="arch"
echo
echo
echo
echo
echo
echo "  ~Setup a Hostname~"
echo
read -p "Enter a Hostname: " HOSTNAME
echo
echo
echo
echo
echo
echo
echo
echo
echo
echo "	There will nolonger be any more questions"
echo "	Follow any instuctions that soon get asked"


DEVICE="/dev/sda"

KEYMAP="uk"

PKG="base base-devel refind-efi wireless_tools nfs-utils ntfs-3g openssh pkgfile pacman-contrib mlocate mlocate alsa-utils"

ASDEP="bash-completion rsync pkgfile-update.timer sshd.socket updatedb.timer"

# clocks
echo "Setting local time"
timedatectl set-ntp true

hwclock --systohc --utc


# keyboard
echo "Loading Uk Keymap for the keyboard"
loadkeys ${KEYMAP}



# Formating
echo "# Wriping Drive and segergating"
sgdisk -Z ${DEVICE}

sgdisk -a 2048 -o ${DEVICE}


echo "Setup UEFI Boot Partition"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" ${DEVICE}

mkfs.vfat ${DEVICE}1

echo "Setup Swap"
sgdisk -n 2:0:+2G -t 2:8200 -c 2:"Swap Partition" ${DEVICE}

echo "Setup Root"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux / Partition" ${DEVICE}

mkfs.ext4 -F ${DEVICE}3

echo "# Mounting Partitions"
mount -vo noatime ${DEVICE}3 /mnt

mkdir -pv /mnt/boot/efi

mount -v ${DEVICE}1 /mnt/boot/efi

echo "Enable Swap Partition"
mkswap ${DEVICE}2

swapon ${DEVICE}2

# Install Required Packages if needed
echo "Downloading and Install reflector installation requirements"
pacman -Sy --noconfirm --needed reflector

# Download and sort Mirrors List from Archlinux.org
echo "Downloading and Ranking mirrors"
reflector --verbose --protocol http --latest 200 --number 20 --sort rate --save /etc/pacman.d/mirrorlist

pacman -Syy

echo "# Installing Main System"
pacstrap /mnt ${PKG}

pacstrap /mnt --asdeps ${ASDEP}

echo "# Creating Fstab Entrys"
genfstab -U /mnt >> /mnt/etc/fstab

# Bootloader #

# Create required directories
mkdir -pv /mnt/boot/efi/EFI/refind/drivers_x64 /mnt/boot/efi/EFI/BOOT/drivers_x64

# Copy over refind system files
cp -v /mnt/usr/share/refind/refind_x64.efi /mnt/boot/efi/EFI/refind/refind_x64.efi

cp -v /mnt/usr/share/refind/refind_x64.efi /mnt/boot/efi/EFI/BOOT/bootx64.efi

cp -v /mnt/usr/share/refind/drivers_x64/ext4_x64.efi /mnt/boot/efi/EFI/refind/drivers_x64/ext4_x64.efi

cp -v /mnt/usr/share/refind/drivers_x64/ext4_x64.efi /mnt/boot/efi/EFI/BOOT/drivers_x64/ext4_x64.efi

cp -v /mnt/usr/share/refind/refind.conf-sample /mnt/boot/efi/EFI/refind/refind.conf

cp -v /mnt/usr/share/refind/refind.conf-sample /mnt/boot/efi/EFI/BOOT/refind.conf

cp -vr /mnt/usr/share/refind/icons /mnt/boot/efi/EFI/refind/

cp -vr /mnt/usr/share/refind/icons /mnt/boot/efi/EFI/BOOT/


# Fetch uuid of root partition
DISK_UUID=$(lsblk ${DEVICE}3 -o uuid -n)

# Create refind boot options config with intel microcode added if intel-ucode is installed
if [ -f "/mnt/boot/intel-ucode.img" ]; then
cat > /mnt/boot/refind_linux.conf <<EOF
"Boot with standard options"        "rw root=UUID=${DISK_UUID}  initrd=/boot/intel-ucode.img initrd=/boot/initramfs-linux.img quiet loglevel=3 udev.log-priority=3"
EOF
else
# Create without microcode added
cat > /mnt/boot/refind_linux.conf <<EOF
"Boot with standard options"        "rw root=UUID=${DISK_UUID}  initrd=/boot/initramfs-linux.img quiet loglevel=3 udev.log-priority=3"
EOF
fi

# Create Boot options config
cat >> /mnt/boot/refind_linux.conf <<EOF
"Boot to single-user mode"          "rw root=UUID=${DISK_UUID}  single"
"Boot to terminal"                  "rw root=UUID=${DISK_UUID}  systemd.unit=multi-user.target"
EOF

# Register rEFInd bootloader
efibootmgr --create --disk ${DEVICE} --part 1 --loader /EFI/refind/refind_x64.efi --label "rEFInd Boot Manager" --verbose

# Core Configuration #

echo "Configuring Network"
rm /mnt/etc/resolv.conf
ln -sf "/run/systemd/resolve/stub-resolv.conf" /mnt/etc/resolv.conf
cat > /mnt/etc/systemd/network/20-wired.network <<NET_EOF
[Match]
Name=en*
[Network]
DHCP=ipv4
NET_EOF

# Set Console keymap
echo "Setting KEYMAP"
echo "KEYMAP=$KEYMAP" >> /mnt/etc/vconsole.conf

# Set Hostname
echo "Setting Hostname"
echo "${HOSTNAME}" > /mnt/etc/hostname

# set location to ireland

echo "Setting Locale to en_IE"

sed -i 's/^en_US.UTF-8/#en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#en_IE.UTF-8/en_IE.UTF-8/' /etc/locale.gen
echo "LANG=en_IE.UTF-8" > /etc/locale.conf
export LANG=en_IE.UTF-8
locale-gen
echo ""

# Set Timezone
echo "Setting Timezone"
ln -sf "/usr/share/zoneinfo/Europe/Dublin" /mnt/etc/localtime

# Enable required services
echo "Setting up Systemd Services"
arch-chroot /mnt systemctl enable systemd-networkd.service systemd-resolved.service

# Finalizing #

# Execute the post configurations within chroot
cp post.sh /mnt/root/
arch-chroot /mnt sh /root/post.sh ${ROOTPASSWORD} ${USERNAME} ${USERPASSWORD}
rm /mnt/root/post.sh

echo "Unmounting Drive Partitions"
swapoff ${DEVICE}2
umount -v /mnt/boot/efi
umount -v /mnt

# Finsihing Note #

echo ""
echo "Finised Core Install"
echo
echo
echo
echo "After reboot login as your user"
