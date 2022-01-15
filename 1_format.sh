#!/bin/sh

DRIVE="nvme1n1"

wipefs --all /dev/${DRIVE}

sgdisk /dev/${DRIVE} -o

sgdisk /dev/${DRIVE} 1::+512M -t 1:ef00
sgdisk /dev/${DRIVE} 2::+4G -t 2:8200
sgdisk /dev/${DRIVE} 3::+50G
sgdisk /dev/${DRIVE} 4::+410G

mkfs.vfat -F32 /dev/${DRIVE}p1
mkswap /dev/${DRIVE}p2
mkfs.ext4 /dev/${DRIVE}p3
mkfs.ext4 /dev/${DRIVE}p4
