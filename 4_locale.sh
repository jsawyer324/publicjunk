#!/bin/sh

HOSTNAME="UltraArch2"
USERNAME="james"


ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ${HOSTNAME} > /etc/hostname


#Create user
useradd -m -G wheel $USERNAME
#Add user to sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
#Set password
passwd $USERNAME

#enable services
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable apcupsd
