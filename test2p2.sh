#!/bin/sh

USERNAME="james"
DRIVE="nvme1n1"

echo "Setting Timezone."
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

#Set root password
echo "Please set root password."
passwd

#Create user
echo "Creating User."
useradd -m -G wheel $USERNAME
#Add user to sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
#Set password
echo "Please set password for user "$USERNAME
passwd $USERNAME

#enable services
echo "Enabling Services."
systemctl enable NetworkManager sddm apcupsd

#Configure Grub
echo "Configuring Grub."
mkdir /boot/efi
mount /dev/${DRIVE}p1 /boot/efi
grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
