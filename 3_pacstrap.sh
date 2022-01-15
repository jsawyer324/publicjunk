#!/bin/sh

pacstrap /mnt base linux linux-firmware base-devel amd-ucode nano sudo networkmanager sof-firmware plasma-desktop xorg konsole dolphin nvidia nvidia-settings efibootmgr grub os-prober dosfstools mtools sddm plasma-pa kscreen pulseaudio pulseaudio-alsa alsa-utils

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
