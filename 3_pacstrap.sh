#!/bin/sh

timedatectl set-ntp true

pacstrap /mnt base linux linux-firmware base-devel amd-ucode nano sudo networkmanager sof-firmware plasma-desktop xorg konsole kate dolphin nvidia nvidia-settings efibootmgr grub os-prober dosfstools mtools sddm plasma-pa kscreen pulseaudio pulseaudio-alsa alsa-utils samba cifs-utils apcupsd cmus mpv htop pianobar

genfstab -U /mnt >> /mnt/etc/fstab

#curl -L -o /mnt/tmp/main.zip https://github.com/jsawyer324/publicjunk/archive.refs/heads/main.zip
#bsdtar xvf /mnt/tmp/main.zip

arch-chroot /mnt
