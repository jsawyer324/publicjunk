#!/bin/sh

clear

# Select disk.
echo "Dont be dumb, the disk you choose will be erased!!"
PS3="Select the disk you want to use: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    echo "Installing on $DRIVE"
    break
done

read -r -p "Please enter the hostname: " HOSTNAME

echo -e "Enter new username:\n"
read USERNAME

echo -e "Enter new password for $USERNAME:\n"
read -s USERPASS


#wipe drive
echo "Wiping Drive."
wipefs -af ${DRIVE}
sgdisk -Zo ${DRIVE}

#partition disk
echo "Partitioning Drive"
sgdisk -n 1::+512M ${DRIVE} -t 1:ef00
sgdisk -n 2::+2G ${DRIVE} -t 2:8200
sgdisk -n 3::+10G ${DRIVE}
sgdisk -n 4:: ${DRIVE}


#format partition
echo "Formatting Paritions"
mkfs.vfat -F32 ${DRIVE}1
mkswap ${DRIVE}2
yes | mkfs.ext4 ${DRIVE}3
yes | mkfs.ext4 ${DRIVE}4

#mount partitions
echo "Mounting Partitions"
mount ${DRIVE}3 /mnt
mkdir /mnt/home
mount ${DRIVE}4 /mnt/home
swapon ${DRIVE}2


echo "Setting ntp."
timedatectl set-ntp true

echo "Initial Pacstrap."
# enable options "color", "ParallelDownloads"
sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ' /etc/pacman.conf

#base
pacstrap /mnt base linux linux-firmware base-devel amd-ucode --noconfirm --needed

#CPU
#AMD
#pacstrap /mnt amd-ucode --noconfirm --needed
#INTEL
pacstrap /mnt intel-ucode --noconfirm --needed

#grub
pacstrap /mnt efibootmgr grub os-prober dosfstools mtools --noconfirm --needed

#admin
pacstrap /mnt nano sudo reflector --noconfirm --needed

#networking
pacstrap /mnt samba cifs-utils nfs-utils ntfs-3g rsync networkmanager --noconfirm --needed
systemctl enable NetworkManager --root=/mnt

#VM Hosts
#qemu
#pacstrap /mnt qemu-guest-agent --noconfirm --needed
#systemctl enable qemu-guest-agent --root=/mnt
#virtualbox
#pacstrap /mnt virtualbox-guest-utils xf86-video-vmware --noconfirm --needed
#systemctl enable vboxservice --root=/mnt

#Video Drivers
#Nvidia
#pacstrap /mnt nvidia nvidia-settings nvidia-utils apcupsd --noconfirm --needed
#Intel
pacstrap /mnt xf86-video-intel mesa --noconfirm --needed

#Other Drivers
#pacstrap /mnt apcupsd --noconfirm --needed

#software
pacstrap /mnt cmus mpv htop pianobar firefox git --noconfirm --needed

#Audio
pacstrap /mnt sof-firmware pulseaudio pulseaudio-alsa alsa-utils --noconfirm --needed

#Bluetooth
#pacstrap /mnt bluez bluez-utils bluedevil pulseaudio-bluetooth --noconfirm --needed

#KDE Plasma
pacstrap /mnt plasma-desktop xorg konsole kate dolphin sddm plasma-pa kscreen --noconfirm --needed
systemctl enable sddm --root=/mnt

#LXQT
#pacstrap /mnt lxqt xdg-utils ttf-freefont sddm xorg libpulse libstatgrab libsysstat lm_sensors network-manager-applet oxygen-icons pavucontrol-qt --noconfirm --needed
#systemctl enable sddm --root=/mnt

#XFCE
#pacstrap /mnt xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
#systemctl enable lightdm --root=/mnt

#i3
#pacstrap /mnt i3-wm dmenu xorg xorg-xinit xterm lightdm lightdm-gtk-greeter --noconfirm --needed
#pacstrap /mnt rofi i3status polybar i3blocks ttf-dejavu --noconfirm --needed
#systemctl enable lightdm --root=/mnt

#vm programs
#pacstrap /mnt firefox torbrowser-launcher

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Setting Hostname."
echo ${HOSTNAME} > /mnt/etc/hostname

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
echo "Generating Locale."
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf


# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
    # Setting up timezone.
    echo "Setting up the timezone."
    ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
    
    # Setting up clock.
    echo "Setting up the system clock."
    hwclock --systohc
    
    #echo "Please set root password."
    echo -e "$USERPASS\n$USERPASS" | passwd root

    #Create user
    echo "Creating User."
    useradd -m -G wheel $USERNAME
    #Add user to sudoers
    #sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    sed -i 's/# %wheel ALL=(ALL/%wheel ALL=(ALL/' /etc/sudoers
    #Set password
    #echo "Please set password for user "$USERNAME
    echo -e "$USERPASS\n$USERPASS" | passwd $USERNAME
   
    
   #Configure Grub
    echo "Configuring Grub."
    mkdir /boot/efi
    mount ${DRIVE}1 /boot/efi
    grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg
    
EOF

umount -a

reboot
