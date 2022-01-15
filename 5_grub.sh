#!/bin/sh

DRIVE="nvme1n1"

mkdir /boot/EFI
mount /dev/${DRIVE}p1 /boot/EFI
grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --recheck

grub-mkconfig -o /boot/grub/grub.cfg
