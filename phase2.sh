#!/bin/sh

HOSTNAME="UltraArch2"
USERNAME="james"
DRIVE="nvme1n1"


ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ${HOSTNAME} > /etc/hostname

#Set root password
passwd

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


mkdir /boot/efi
mount /dev/${DRIVE}p1 /boot/efi
grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck

grub-mkconfig -o /boot/grub/grub.cfg
