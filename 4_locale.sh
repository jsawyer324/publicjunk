#!/bin/sh

HOSTNAME="UltraArch2"

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ${HOSTNAME} > /etc/hostname

useradd -m james

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable apcupsd
