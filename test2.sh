#!/bin/sh

DRIVE="/dev/nvme1n1"

#wipe drive
echo "Wiping Drive."
wipefs -af ${DRIVE}
sgdisk -Zo ${DRIVE}

#partition disk
echo "Partitioning Drive"
sgdisk -n 1::+512M ${DRIVE} -t 1:ef00
sgdisk -n 2::+4G ${DRIVE} -t 2:8200
sgdisk -n 3::+50G ${DRIVE}
sgdisk -n 4::+410G ${DRIVE}

#format partition
echo "Formatting Paritions"
mkfs.vfat -F32 ${DRIVE}p1
mkswap ${DRIVE}p2
yes | mkfs.ext4 ${DRIVE}p3
yes | mkfs.ext4 ${DRIVE}p4

#mount partitions
echo "Mounting Partitions"
mount /dev/${DRIVE}p3 /mnt
mkdir /mnt/home
mount /dev/${DRIVE}p4 /mnt/home
swapon /dev/${DRIVE}p2

echo "Setting ntp."
timedatectl set-ntp true

echo "Initial Pacstrap."

#base
pacstrap /mnt base linux linux-firmware base-devel amd-ucode

#grub
pacstrap /mnt efibootmgr grub os-prober dosfstools mtools

#admin
pacstrap /mnt nano sudo 

#networking
pacstrap /mnt samba cifs-utils rsync networkmanager

#Drivers
pacstrap /mnt nvidia nvidia-settings apcupsd

#software
pacstrap /mnt cmus mpv htop pianobar firefox

#Audio
pacstrap /mnt sof-firmware pulseaudio pulseaudio-alsa alsa-utils

#KDE
pacstrap /mnt plasma-desktop xorg konsole kate dolphin sddm plasma-pa kscreen



echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


#Prepare and launch phase2
echo "Prepping Phase 2."
curl https://raw.githubusercontent.com/jsawyer324/publicjunk/main/phase2.sh -o /mnt/root/phase2.sh
chmod a+x /mnt/root/phase2.sh

arch-chroot /mnt /root/phase2.sh

umount -a

reboot
