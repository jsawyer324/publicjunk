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
clear

read -rp "Please enter the hostname: " HOSTNAME
clear

read -rp "Enter new username [james]:" USERNAME
USERNAME=${USERNAME:-james}
clear

read -rsp "Enter new password for $USERNAME: " USERPASS
# echo -e "/n"
# read -rsp"Renter password: " USERPASS2
clear


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

#Detect Microcode
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"* ]]; then
    print "An AMD CPU has been detected, the AMD microcode will be installed."
    microcode="amd-ucode"
else
    print "An Intel CPU has been detected, the Intel microcode will be installed."
    microcode="intel-ucode"
fi


#base
#pacstrap /mnt base linux linux-firmware base-devel --noconfirm --needed
pacstrap /mnt base linux $microcode --noconfirm --needed

#----------------------------

#CPU
#AMD
#pacstrap /mnt amd-ucode --noconfirm --needed
#INTEL
#pacstrap /mnt intel-ucode --noconfirm --needed


#Video Drivers
#Nvidia
#pacstrap /mnt nvidia nvidia-settings nvidia-utils --noconfirm --needed
#Intel
#pacstrap /mnt xf86-video-intel mesa --noconfirm --needed


gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacstrap /mnt nvidia nvidia-settings nvidia-utils --noconfirm --needed
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacstrap /mnt xf86-video-amdgpu --noconfirm --needed 
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacstrap /mnt libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --noconfirm --needed
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacstrap /mnt libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --noconfirm --needed
fi

#----------------------------

#grub
#pacstrap /mnt efibootmgr grub os-prober dosfstools mtools --noconfirm --needed
pacstrap /mnt efibootmgr grub --noconfirm --needed

#admin
#pacstrap /mnt nano sudo reflector htop git openssh --noconfirm --needed
pacstrap /mnt nano sudo --noconfirm --needed
systemctl enable sshd --root=/mnt

#networking
#pacstrap /mnt samba cifs-utils nfs-utils ntfs-3g rsync networkmanager --noconfirm --needed
pacstrap /mnt networkmanager --noconfirm --needed
systemctl enable NetworkManager --root=/mnt

#VM Hosts
#qemu
#pacstrap /mnt qemu-guest-agent --noconfirm --needed
#systemctl enable qemu-guest-agent --root=/mnt
#virtualbox
pacstrap /mnt virtualbox-guest-utils xf86-video-vmware --noconfirm --needed
systemctl enable vboxservice --root=/mnt

#Other Drivers
#pacstrap /mnt apcupsd broadcom-wl --noconfirm --needed

#software
#pacstrap /mnt cmus mpv pianobar firefox --noconfirm --needed

#Audio
#pacstrap /mnt sof-firmware pulseaudio pulseaudio-alsa alsa-utils pavucontrol --noconfirm --needed

#Bluetooth
#pacstrap /mnt bluez bluez-utils bluedevil pulseaudio-bluetooth --noconfirm --needed
#systemctl enable bluetooth --root=/mnt

#xorg
#pacstrap /mnt xorg-server xorg-apps xorg-xinit --noconfirm --needed

#KDE Plasma
#pacstrap /mnt plasma-desktop plasma-pa plasma-nm plasma-systemmonitor kscreen sddm discover packagekit-qt5 ark filelight kate kcalc konsole kwalletmanager kwallet-pam powerdevil gwenview spectacle okular dolphin --noconfirm --needed
#pacstrap /mnt plasma-desktop konsole kate dolphin filelight ark kcalc sddm plasma-pa plasma-nm kscreen --noconfirm --needed
#systemctl enable sddm --root=/mnt

#LXQT
#pacstrap /mnt lxqt xdg-utils ttf-freefont sddm libpulse libstatgrab libsysstat lm_sensors network-manager-applet oxygen-icons pavucontrol-qt --noconfirm --needed
#systemctl enable sddm --root=/mnt

#XFCE
#pacstrap /mnt xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
#systemctl enable lightdm --root=/mnt

#i3
#pacstrap /mnt i3-wm i3blocks i3lock i3status numlockx lightdm lightdm-gtk-greeter ranger dmenu kitty --noconfirm --needed
#pacstrap /mnt noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont ttf-liberation ttf-droid ttf-roboto terminus-font --noconfirm --needed
#systemctl enable lightdm --root=/mnt

#Awesome - wip
#pacstrap /mnt awesome xterm xorg-twm xorg-xclock --noconfirm --needed

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

#sleep 20

umount -a

reboot
