#!/bin/sh

DRIVE="nvme1n1"

mkdir /boot/efi
mount /dev/${DRIVE}p1 /boot/efi
grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck

grub-mkconfig -o /boot/grub/grub.cfg
