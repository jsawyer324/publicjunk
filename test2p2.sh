#!/bin/sh

USERNAME="james"
DRIVE="/dev/nvme1n1"

echo -e "Enter new password for $USERNAME:\n"
read userpass

echo "Setting Timezone."
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

#Set root password
echo "Please set root password."
echo -e "$userpass\n$userpass" | passwd root

#Create user
echo "Creating User."
useradd -m -G wheel $USERNAME
#Add user to sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
#Set password
echo "Please set password for user "$USERNAME
echo -e "$userpass\n$userpass" | passwd $USERNAME

#enable services
echo "Enabling Services."
systemctl enable NetworkManager sddm apcupsd

#Configure Grub
echo "Configuring Grub."
mkdir /boot/efi
mount ${DRIVE}p1 /boot/efi
grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
