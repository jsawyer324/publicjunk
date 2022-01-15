#!/bin/sh

pacstrap /mnt base linux linux-firmware base-devel nano sudo networkmanager sof-firmware plasma-desktop xorg kitty nemo nvidia nvidia-settings efibootmgr grub os-prober dosfstools mtools sddm

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
