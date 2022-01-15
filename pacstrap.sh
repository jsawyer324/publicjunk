#!/bin/sh

pacstrap /mnt base linux linux-firmware base-devel nano sudo networkmanager sof-firmware plasma-desktop xorg kitty nemo

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc
