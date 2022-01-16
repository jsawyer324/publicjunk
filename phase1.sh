#!/bin/sh

DRIVE="nvme1n1"

wipefs --all /dev/${DRIVE}

sgdisk -Z ${DRIVE}
sgdisk /dev/${DRIVE} -o

sgdisk -n 1::+512M /dev/${DRIVE} -t 1:ef00
sgdisk -n 2::+4G /dev/${DRIVE} -t 2:8200
sgdisk -n 3::+50G /dev/${DRIVE}
sgdisk -n 4::+410G /dev/${DRIVE}

mkfs.vfat -F32 /dev/${DRIVE}p1
mkswap /dev/${DRIVE}p2
mkfs.ext4 /dev/${DRIVE}p3
mkfs.ext4 /dev/${DRIVE}p4

mount /dev/${DRIVE}p3 /mnt

mkdir /mnt/home
mount /dev/${DRIVE}p4 /mnt/home

#mkdir /mnt/efi
#mount /dev/${DRIVE}p1 /mnt/efi

swapon /dev/${DRIVE}p2

timedatectl set-ntp true

pacstrap /mnt base linux linux-firmware base-devel amd-ucode nano sudo networkmanager sof-firmware plasma-desktop xorg konsole kate dolphin nvidia nvidia-settings efibootmgr grub os-prober dosfstools mtools sddm plasma-pa kscreen pulseaudio pulseaudio-alsa alsa-utils samba cifs-utils apcupsd cmus mpv htop pianobar

genfstab -U /mnt >> /mnt/etc/fstab

#curl -L -o /mnt/tmp/main.zip https://github.com/jsawyer324/publicjunk/archive.refs/heads/main.zip
#bsdtar xvf /mnt/tmp/main.zip

#arch-chroot /mnt
