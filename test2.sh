#!/bin/sh

HOSTNAME="UltraArch2"
USERNAME="james"
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
mount ${DRIVE}p3 /mnt
mkdir /mnt/home
mount ${DRIVE}p4 /mnt/home
swapon ${DRIVE}p2

echo "Setting ntp."
timedatectl set-ntp true

echo "Initial Pacstrap."

# enable options "color", "ParallelDownloads", "multilib (32-bit) repository"
sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ; s #\[multilib\] \[multilib\] ; /\[multilib\]/{n;s #Include Include }' /etc/pacman.conf

#base
pacstrap /mnt base linux linux-firmware base-devel amd-ucode

#grub
pacstrap /mnt efibootmgr grub os-prober dosfstools mtools

#admin
pacstrap /mnt nano sudo 

#networking
pacstrap /mnt samba cifs-utils nfs-utils rsync networkmanager

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

echo "Setting Hostname."
echo ${HOSTNAME} > /mnt/etc/hostname

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
echo "Generating Locale."
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf


#Prepare and launch phase2
echo "Prepping Phase 2."
curl https://raw.githubusercontent.com/jsawyer324/publicjunk/main/test2p2.sh -o /mnt/root/test2p2.sh
chmod a+x /mnt/root/test2p2.sh

arch-chroot /mnt /root/test2p2.sh

umount -a

reboot
