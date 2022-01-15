#!/bin/sh

DRIVE="nvme1n1"

wipefs --all /dev/${DRIVE}

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
