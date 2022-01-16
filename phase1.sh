#!/bin/sh

DRIVE="nvme1n1"

#wipe drive
echo "Wiping Drive."
wipefs -af /dev/${DRIVE}
sgdisk -Zo /dev/${DRIVE}

#partition disk
echo "Partitioning Drive"
sgdisk -n 1::+512M /dev/${DRIVE} -t 1:ef00
sgdisk -n 2::+4G /dev/${DRIVE} -t 2:8200
sgdisk -n 3::+50G /dev/${DRIVE}
sgdisk -n 4::+410G /dev/${DRIVE}

#format partition
echo "Formatting Paritions"
mkfs.vfat -F32 /dev/${DRIVE}p1
mkswap /dev/${DRIVE}p2
mkfs.ext4 -f /dev/${DRIVE}p3
mkfs.ext4 -f /dev/${DRIVE}p4

#mount partitions
echo "Mounting Partitions"
mount /dev/${DRIVE}p3 /mnt
mkdir /mnt/home
mount /dev/${DRIVE}p4 /mnt/home
swapon /dev/${DRIVE}p2

echo "Setting ntp."
timedatectl set-ntp true

echo "Initial Pacstrap."
pacstrap /mnt base linux linux-firmware base-devel amd-ucode nano sudo networkmanager sof-firmware plasma-desktop xorg konsole kate dolphin nvidia nvidia-settings efibootmgr grub os-prober dosfstools mtools sddm plasma-pa kscreen pulseaudio pulseaudio-alsa alsa-utils samba cifs-utils apcupsd cmus mpv htop pianobar firefox rsync

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


#Prepare and launch phase2
echo "Prepping Phase 2."
curl https://raw.githubusercontent.com/jsawyer324/publicjunk/main/phase2.sh -o /mnt/root/phase2.sh
#cp ./phase2.sh /mnt/root/
chmod a+x /mnt/root/phase2.sh

arch-chroot /mnt /root/phase2.sh

umount -a

reboot
