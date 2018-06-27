#!/usr/bin/env bash

set -e
set -u

# check if system is uefi
if [ ! -d "/sys/firmware/efi/" ]; then
	echo "Sorry, this script only supports UEFI mode"
	exit 1
fi

VARTARGETDIR="/mnt"
DEVICE="/dev/sda"
KEYMAP="uk"

DAEMONS=""

EXTRAPKG="base base-devel refind-efi"
OPTIONALDEP="bash-completion"

# Setup

handelCanceled()
{
    if [ $1 != 0 ]; then
        exit $1
    fi
}

selectDisk()
{
        MENU=""
        for disk in $(lsblk -l | grep disk | awk '{print $1}'); do
                MODEL=$(hdparm -I /dev/${disk} | awk -F':' '/Model Number/ { print $2 }' | sed 's/^[ \t]*//;s/[ \t]*$//')
                SIZE=$(hdparm -I /dev/${disk} | grep "device size with M = 1000" | awk -F'(' '{ print $2 }' | sed 's/^[ \t]*//;s/[ \t]*$//' | rev | cut -c 2- | rev)
                MENU="$MENU '/dev/$disk' '$MODEL - $SIZE'"
        done
        DEVICE=$(echo ${MENU} | xargs dialog --title "Drive Selection" --menu "Please select drive in witch to install Arch Linux.\nWARNING: All data on selected drive will be WIPED clean." 13 60 10 --output-fd 1)
        handelCanceled $?
}

requestPackages()
{
	dialog --title "Optional Packages" --checklist "Please Select Optional Packages:" 15 55 5 1 "openssh" on 2 "reflector" on 3 "mlocate" on 4 "pkgfile" on 5 "pacman-contrib" on 2>/tmp/menuitem
	handelCanceled $?
	for pkg in $(cat /tmp/menuitem); do
		if [ "$pkg" = 1 ]; then
		    # openssh		= Free version of the SSH connectivity tools            = https://www.archlinux.org/packages/core/x86_64/openssh/
			EXTRAPKG="$EXTRAPKG openssh"
			DAEMONS="$DAEMONS sshd.socket"

		elif [ "$pkg" = 2 ]; then
		    # reflector		= Retrieve and filter the latest Pacman mirror list		= https://www.archlinux.org/packages/community/any/reflector/
			# rsync 		= A file transfer program to keep remote files in sync	= https://www.archlinux.org/packages/extra/x86_64/rsync/
			EXTRAPKG="$EXTRAPKG reflector"
			OPTIONALDEP="$OPTIONALDEP rsync"

		elif [ "$pkg" = 3 ]; then
		    # mlocate	    = Merging locate/updatedb implementation	= https://www.archlinux.org/packages/core/x86_64/mlocate/
			EXTRAPKG="$EXTRAPKG mlocate"
			DAEMONS="$DAEMONS updatedb.timer"

		elif [ "$pkg" = 4 ]; then
		    # pkgfile	    = A pacman files metadata explorer		    = https://www.archlinux.org/packages/extra/x86_64/pkgfile/
			EXTRAPKG="$EXTRAPKG pkgfile"
			DAEMONS="$DAEMONS pkgfile-update.timer"
		elif [ "$pkg" = 5 ]; then
		    # pacman-contrib    = Contributed scripts and tools for pacman systems      = https://www.archlinux.org/packages/community/x86_64/pacman-contrib/
		    EXTRAPKG="$EXTRAPKG pacman-contrib"
		fi
	done
}

requestHostname()
{
	HOSTNM=""
	while [ "$HOSTNM" = "" ]
	do
		HOSTNM=$(dialog --title "Hostname" --inputbox "Please enter hostname:" 8 50 --output-fd 1)
		handelCanceled $?
	done
}

requestRoot()
{
        ROOTPASSWORD=""
        CONFIRM="-"
        while [ "$ROOTPASSWORD" != "$CONFIRM" ]; do
                ROOTPASSWORD=$(dialog --title "Root Password" --insecure --passwordbox "Please enter Root Password:" 8 50 --output-fd 1)
                handelCanceled $?

                CONFIRM=$(dialog --title "Root Password" --insecure --passwordbox "Please comfirm Root Password:" 8 50 --output-fd 1)
                handelCanceled $?

                if [ "$ROOTPASSWORD" == "" ]; then
                    dialog --msgbox "A Password is Requred, Please try again.." 8 50
                    CONFIRM="-"
                elif [ "$ROOTPASSWORD" != "$CONFIRM" ]; then
                    dialog --msgbox "Password did not match, Please try again." 8 50
                fi
        done
        unset EXITCODE
        unset CONFIRM
}

requestUser()
{
    USERNAME=""
    while [ "$USERNAME" = "" ]; do
        USERNAME=$(dialog --title "Username" --inputbox "Please enter Username:" 8 50 --output-fd 1)
        handelCanceled $?
    done
    requestUserPass
}

requestUserPass()
{
    USERPASS=""
    CONFIRM="-"
    while [ "$USERPASS" != "$CONFIRM" ]; do
            USERPASS=$(dialog --title "User Password" --insecure --passwordbox "Please enter Password for $USERNAME:" 8 50 --output-fd 1)
            handelCanceled $?

            CONFIRM=$(dialog --title "User Password" --insecure --passwordbox "Please comfirm Password for $USERNAME:" 8 50 --output-fd 1)
            handelCanceled $?

            if [ "$USERPASS" == "" ]; then
                dialog --msgbox "A Password is Requred, Please try again.." 8 50
                CONFIRM="-"
            elif [ "$USERPASS" != "$CONFIRM" ]; then
                dialog --msgbox "Password did not match, Please try again." 8 50
            fi
    done
    unset EXITCODE
    unset CONFIRM
}

confirmation()
{
        data="sda"
        dialog --title "Warning" --yesno "From here on, you will not be asked any more questions, and all data on drive /dev/$data will be Wiped.\n\nAre you sure you want to continue." 10 50
        handelCanceled $?
}

# Check if system has a Audio device
if [[ -n $(lspci | grep -i "Multimedia audio controller:") ]] || [[ -n $(lspci | grep -i "Audio device:") ]]; then
	# alsa-utils		= An implementation of Linux sound support		= https://www.archlinux.org/packages/extra/x86_64/alsa-utils/
	EXTRAPKG="$EXTRAPKG alsa-utils"
fi



selectDisk
requestPackages
requestHostname
requestRoot
requestUser
confirmation
clear

echo "Loading Uk Keyboard Layout"
loadkeys ${KEYMAP}

echo "Syncing clocks"
timedatectl set-ntp true
hwclock --systohc --utc

echo "Setting Locale to en_IE"
sed -i 's/^en_US.UTF-8/#en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#en_IE.UTF-8/en_IE.UTF-8/' /etc/locale.gen
echo "LANG=en_IE.UTF-8" > /etc/locale.conf
export LANG=en_IE.UTF-8
locale-gen
echo ""


##################
## Partitioning ##
##################

# Formating Disks
echo "# Wriping Drive"
sgdisk -Z ${DEVICE}
sgdisk -a 2048 -o ${DEVICE}

echo "Setup UEFI Boot Partition"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" ${DEVICE}
mkfs.vfat ${DEVICE}1

echo "Setup Swap Partition"
sgdisk -n 2:0:+2G -t 2:8200 -c 2:"Swap Partition" ${DEVICE}

echo "Setup Root Partition"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux / Partition" ${DEVICE}
mkfs.ext4 -F ${DEVICE}3

echo "# Mounting Partitions"
mount -vo noatime ${DEVICE}3 ${VARTARGETDIR}
mkdir -pv ${VARTARGETDIR}/boot/efi
mount -v ${DEVICE}1 ${VARTARGETDIR}/boot/efi

echo "Enable Swap Partition"
mkswap ${DEVICE}2
swapon ${DEVICE}2

######################
## Install Packages ##
######################

# Install Required Packages if needed
echo "Downloading and Install reflector installation requirements"
pacman -Sy --noconfirm --needed reflector

# Download and sort Mirrors List from Archlinux.org
echo "Downloading and Ranking mirrors"
reflector --verbose --protocol http --latest 200 --number 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy

echo "# Installing Main System"
pacstrap ${VARTARGETDIR} ${EXTRAPKG}
pacstrap ${VARTARGETDIR} --asdeps ${OPTIONALDEP}

echo "# Creating Fstab Entrys"
genfstab -U ${VARTARGETDIR} >> ${VARTARGETDIR}/etc/fstab


################
## Bootloader ##
################

# Create required directories
mkdir -pv ${VARTARGETDIR}/boot/efi/EFI/refind/drivers_x64 ${VARTARGETDIR}/boot/efi/EFI/BOOT/drivers_x64

# Copy over refind system files
cp -v ${VARTARGETDIR}/usr/share/refind/refind_x64.efi ${VARTARGETDIR}/boot/efi/EFI/refind/refind_x64.efi
cp -v ${VARTARGETDIR}/usr/share/refind/refind_x64.efi ${VARTARGETDIR}/boot/efi/EFI/BOOT/bootx64.efi
cp -v ${VARTARGETDIR}/usr/share/refind/drivers_x64/ext4_x64.efi ${VARTARGETDIR}/boot/efi/EFI/refind/drivers_x64/ext4_x64.efi
cp -v ${VARTARGETDIR}/usr/share/refind/drivers_x64/ext4_x64.efi ${VARTARGETDIR}/boot/efi/EFI/BOOT/drivers_x64/ext4_x64.efi
cp -v ${VARTARGETDIR}/usr/share/refind/refind.conf-sample ${VARTARGETDIR}/boot/efi/EFI/refind/refind.conf
cp -v ${VARTARGETDIR}/usr/share/refind/refind.conf-sample ${VARTARGETDIR}/boot/efi/EFI/BOOT/refind.conf
cp -vr ${VARTARGETDIR}/usr/share/refind/icons ${VARTARGETDIR}/boot/efi/EFI/refind/
cp -vr ${VARTARGETDIR}/usr/share/refind/icons ${VARTARGETDIR}/boot/efi/EFI/BOOT/

# Fetch uuid of root partition
DISK_UUID=$(lsblk ${DEVICE}3 -o uuid -n)

# Create refind boot options config with intel microcode added if intel-ucode is installed
if [ -f "${VARTARGETDIR}/boot/intel-ucode.img" ]; then
cat > ${VARTARGETDIR}/boot/refind_linux.conf <<EOF
"Boot with standard options"        "rw root=UUID=${DISK_UUID}  initrd=/boot/intel-ucode.img initrd=/boot/initramfs-linux.img quiet loglevel=3 udev.log-priority=3"
EOF
else
# Create without microcode added
cat > ${VARTARGETDIR}/boot/refind_linux.conf <<EOF
"Boot with standard options"        "rw root=UUID=${DISK_UUID}  initrd=/boot/initramfs-linux.img quiet loglevel=3 udev.log-priority=3"
EOF
fi

# Create Boot options config
cat >> ${VARTARGETDIR}/boot/refind_linux.conf <<EOF
"Boot to single-user mode"          "rw root=UUID=${DISK_UUID}  single"
"Boot to terminal"                  "rw root=UUID=${DISK_UUID}  systemd.unit=multi-user.target"
EOF

# Register rEFInd bootloader
efibootmgr --create --disk ${DEVICE} --part 1 --loader /EFI/refind/refind_x64.efi --label "rEFInd Boot Manager" --verbose


########################
## Core Configuration ##
########################

echo "Configuring Network"
DAEMONS="$DAEMONS systemd-networkd.service systemd-resolved.service"
rm ${VARTARGETDIR}/etc/resolv.conf
ln -sf "/run/systemd/resolve/stub-resolv.conf" ${VARTARGETDIR}/etc/resolv.conf
cat > ${VARTARGETDIR}/etc/systemd/network/20-wired.network <<NET_EOF
[Match]
Name=en*
[Network]
DHCP=ipv4
NET_EOF

# Set Console keymap
echo "Setting KEYMAP"
echo "KEYMAP=$KEYMAP" >> ${VARTARGETDIR}/etc/vconsole.conf

# Set Hostname
echo "Setting Hostname"
echo "${HOSTNM}" > ${VARTARGETDIR}/etc/hostname

# Set Locale Settings
echo "Setting Locale"
sed -i 's/^#en_IE.UTF-8 UTF-8/en_IE.UTF-8 UTF-8/' ${VARTARGETDIR}/etc/locale.gen
echo 'LANG=en_IE.UTF-8' > ${VARTARGETDIR}/etc/locale.conf

# Set Timezone
echo "Setting Timezone"
ln -sf "/usr/share/zoneinfo/Europe/Dublin" ${VARTARGETDIR}/etc/localtime

# Enable required services
echo "Setting up Systemd Services"
arch-chroot ${VARTARGETDIR} systemctl enable ${DAEMONS}


################
## Finalizing ##
################

# Execute the post configurations within chroot
cp post.sh ${VARTARGETDIR}/root/
arch-chroot ${VARTARGETDIR} sh /root/post.sh ${ROOTPASSWORD} ${USERNAME} ${USERPASS}
cp -rv scripts ${VARTARGETDIR}/opt/install-scripts
rm ${VARTARGETDIR}/root/post.sh

echo "Unmounting Drive Partitions"
swapoff ${DEVICE}2
umount -v ${VARTARGETDIR}/boot/efi
umount -v ${VARTARGETDIR}

echo ""
echo "##########################################"
echo "##               All Done               ##"
echo "##########################################"
echo "## Don't forget to execute after reboot ##"
echo "## >>> timedatectl set-ntp true         ##"
echo "##########################################"
echo "## Please see '/opt/install-scripts'    ##"
echo "## for extra post install scripts       ##"
echo "##########################################"
