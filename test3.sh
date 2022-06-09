#!/bin/sh


#config
version="8"
BOOTLOADER="systemd" #systemd or grub


clear

# Select disk.
echo "Version "$version
echo "Dont be dumb, the disk you choose will be erased!!"
PS3="Select the disk you want to use: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    echo "Installing on $DRIVE"
    break
done
clear

read -rp "Please enter the hostname [test]: " HOSTNAME
HOSTNAME=${HOSTNAME:-test}
clear

read -rp "Enter new username [james]:" USERNAME
USERNAME=${USERNAME:-james}
clear

read -rsp "Enter new password for $USERNAME: " USERPASS
# echo -e "/n"
# read -rsp"Renter password: " USERPASS2
clear

#Select DE
PS3="Select a DE: "
select DE in Plasma Gnome XFCE i3 Awesome LXQT Server
do
    DESKTOP=$DE
    break
done
clear

#Select Full or Min install
PS3="Install Type? : "
select IT in full minimal miniarchvm
do
    INSTALLTYPE=$IT
    break
done
clear

#------------------------

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

if [ $BOOTLOADER == "systemd" ]; then
mkdir -p /mnt/boot
mount ${DRIVE}1 /mnt/boot
elif [ $BOOTLOADER == "grub" ]; then
mkdir -p /mnt/boot/efi
mount ${DRIVE}1 /mnt/boot/efi
APPS+="efibootmgr grub "
fi

echo "drive config done"

#-------------------------

echo "Setting ntp."
timedatectl set-ntp true

echo "Initial Pacstrap."
# enable options "color", "ParallelDownloads"
sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ' /etc/pacman.conf

#base
COREINSTALL+="base base-devel linux linux-firmware "


#Detect Microcode
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"* ]]; then
    echo "An AMD CPU has been detected, the AMD microcode will be installed."
    BASEINSTALL+="amd-ucode "
else
    echo "An Intel CPU has been detected, the Intel microcode will be installed."
    BASEINSTALL+="intel-ucode "
fi


#----------------------------

hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )       echo "KVM has been detected."
                    BASEINSTALL+="qemu-guest-agent "
                    SERVICES+="qemu-guest-agent "
                    ;;
        vmware  )   echo "VMWare Workstation/ESXi has been detected."
                    BASEINSTALL+="open-vm-tools "
                    SERVICES+="vmtoolsd vmware-vmblock-fuse "
                    ;;
        oracle )    echo "VirtualBox has been detected."
                    BASEINSTALL+="virtualbox-guest-utils "
                    SERVICES+="vboxservice "
                    ;;
        microsoft ) echo "Hyper-V has been detected."
                    BASEINSTALL+="hyperv "
                    SERVICES+="hv_fcopy_daemon hv_kvp_daemon hv_vss_daemon "
                    ;;
        * ) ;;
    esac
#----------------------------

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    BASEINSTALL+="nvidia nvidia-settings nvidia-utils "
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    BASEINSTALL+="xf86-video-amdgpu "
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
fi

#----------------------------

#admin
#APPS+="nano reflector htop git openssh "
#SERVICES+="sshd "
APPS+="nano "

#networking
#APPS+="samba cifs-utils nfs-utils ntfs-3g rsync networkmanager "
APPS+="networkmanager "
SERVICES+="NetworkManager "

#Other Drivers
#APPS+="apcupsd broadcom-wl "

#software
#APPS+="cmus mpv pianobar firefox "

#Audio
#APPS+="sof-firmware pulseaudio pulseaudio-alsa alsa-utils pavucontrol "

#Bluetooth
#APPS+="bluez bluez-utils bluedevil pulseaudio-bluetooth "
#SERVICES+="bluetooth "

#Xorg
xorg="xorg-server xorg-apps xorg-xinit "

case $DESKTOP in
    Plasma )    #KDE Plasma
                APPS+="plasma-desktop plasma-pa plasma-nm plasma-systemmonitor kscreen sddm discover packagekit-qt5 ark filelight kate kcalc konsole kwalletmanager kwallet-pam powerdevil gwenview spectacle okular dolphin "
                #APPS+="plasma-desktop konsole kate dolphin filelight ark kcalc sddm plasma-pa plasma-nm kscreen "
                APPS+=$xorg
                SERVICES+="sddm "
                ;;
    Gnome )     #Gnome
                APPS+="gnome gnome-tweaks gnome-packagekit-plugin "
                APPS+=$xorg
                SERVICES+="gdm "
                ;;
    XFCE )      #XFCE
                APPS+="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter "$xorg
                SERVICES+="lightdm "
                ;;
    i3 )        #i3
                APPS+="i3-wm i3blocks i3lock i3status numlockx lightdm lightdm-gtk-greeter ranger dmenu kitty "
                APPS+="noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont ttf-liberation ttf-droid ttf-roboto terminus-font "
                APPS+=$xorg
                SERVICES+="lightdm "
                ;;
    Awesome )   #Awesome - wip
                APPS+="awesome xterm xorg-twm xorg-xclock "
                APPS+=$xorg
                ;;
    LXQT )      #LXQT
                APPS+="lxqt xdg-utils ttf-freefont sddm libpulse libstatgrab libsysstat lm_sensors network-manager-applet oxygen-icons pavucontrol-qt "
                APPS+=$xorg
                SERVICES+="sddm "
                ;;
    Server )    #Server
                ;;  
    * )         ;;
esac


#vm programs
if [ $INSTALLTYPE == "miniarchvm" ] && [ $hypervisor != "none" ]; then
APPS+="firefox torbrowser-launcher networkmanager-openvpn network-manager-applet ufw git base-devel "
SERVICES+="ufw "
fi

#-------------------

pacstrap /mnt $COREINSTALL --noconfirm --needed

#------------------

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Setting Hostname."
echo ${HOSTNAME} > /mnt/etc/hostname

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
echo "Generating Locale."
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#LANGUAGE
#LC_ALL
#LC_MESSAGES

echo "Setting up the timezone."
ln -sf /mnt/usr/share/zoneinfo/America/Chicago /mnt/etc/localtime

#------------------
echo "BASEINSTALL..."
echo $BASEINSTALL
sleep 10
pacstrap /mnt $BASEINSTALL --noconfirm --needed
echo "APPS..."
echo $APPS
sleep 10
pacstrap /mnt $APPS --noconfirm --needed
systemctl enable $SERVICES --root=/mnt

#------------------

# Bootloader Installation
if [ $BOOTLOADER == "systemd" ]; then
    echo "Configuring Systemd-boot."
    bootctl --path=/mnt/boot$esp install
    echo -e "title Arch Linux \nlinux /vmlinuz-linux \ninitrd /initramfs-linux.img \noptions root=${DRIVE}3 rw" >> /mnt/boot/loader/entries/arch.conf
fi

# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
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
    echo -e "$USERPASS\n$USERPASS" | passwd $USERNAME
    
    if [ $BOOTLOADER == "grub" ]; then
        echo "Configuring Grub."
        grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
   
   
EOF


#echo "rebooting in 10 seconds"
#sleep 10


umount -R /mnt

#echo "waiting for reboot"

reboot
