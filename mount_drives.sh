#!/bin/sh

DRIVE="nvme1n1"

mount /dev/${DRIVE}p3 /mnt

mkdir /mnt/home
mount /dev/${DRIVE}p4 /mnt/home

mkdir /mnt/efi
mount /dev/${DRIVE}p1 /mnt/efi

swapon /dev/${DRIVE}p2
