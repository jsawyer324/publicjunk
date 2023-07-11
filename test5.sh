#!/bin/bash

#config ------------------
VERSION="42"
#FILESYSTEM="ext4"   #not currently used
KERNEL="linux"
TIMEZONE="America/Chicago"
BOOTLOADER="systemd" #systemd or grub
#SIZE_SWAP="8G"
#SIZE_ROOT="120G"
SIZE_MBR="1G"   #MBR size
SIZE_ESP="1G"   #ESP - EFI System Partition
SIZE_SWAP="2G"
SIZE_ROOT="15G"


#funtions ----------------
show_version(){
    echo "Version "$VERSION
}
get_usersetup(){
    read -rp "Enter new username [james]:" USERNAME
    USERNAME=${USERNAME:-james}
    get_password "PASSWORD"
}
get_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" != "$PASSWORD2" ]]; then
        echo -ne "ERROR! Passwords do not match. \n"
        get_password
    fi
}
calculate_size(){
    echo "size calculation"
    #lsblk -dbno SIZE /dev/nvme0n1
}
get_drive(){
    lsblk -dpno NAME,MODEL
    echo -ne "\nDont be dumb, the disk you choose will be erased!!\n\n"
    PS3="Select the disk you want to use: "
    select ENTRY in $(lsblk -dpno NAME|grep -P "/dev/sd|nvme|vd");
    do
        DISK=${ENTRY}
        break
    done
}
choose_bootloader(){
    if [[ -d "/sys/firmware/efi" ]]; then
        UEFI=true
        if [ $BOOTLOADER == "systemd" ]; then
            SERVICES+="systemd-boot-update "
        elif [ $BOOTLOADER == "grub" ]; then
            APPS+="efibootmgr grub "
        fi
    else
        BOOTLOADER="grub"
        APPS+="grub "
    fi
}
set_partitions(){
    if [[ "${DISK}" =~ "nvme" ]]; then
        PARTITION1=${DISK}p1
        PARTITION2=${DISK}p2
        PARTITION3=${DISK}p3
        PARTITION4=${DISK}p4
    else
        PARTITION1=${DISK}1
        PARTITION2=${DISK}2
        PARTITION3=${DISK}3
        PARTITION4=${DISK}4
    fi
}
format_drive(){
    #wipe drive
    echo "Wiping Drive -------------------"
    wipefs -af "${DISK}"
    sgdisk -Zo "${DISK}"

    #partition disk
    echo "Partitioning Drive -------------------"
    if [[ -d "/sys/firmware/efi" ]]; then
        sgdisk -n 1::+"${SIZE_ESP}" "${DISK}" -t 1:ef00    #for uefi
    else
        sgdisk -n 1::+"${SIZE_MBR}" "${DISK}" -t 1:ef02   #for bios
    fi
    sgdisk -n 2::+"${SIZE_SWAP}" "${DISK}" -t 2:8200
    sgdisk -n 3::+"${SIZE_ROOT}" "${DISK}"
    sgdisk -n 4:: "${DISK}"

    #format partition
    echo "Formatting Paritions -------------------"
    if [[ -d "/sys/firmware/efi" ]]; then
        mkfs.vfat -F32 $PARTITION1
    fi
    mkswap $PARTITION2
    yes | mkfs.ext4 $PARTITION3
    yes | mkfs.ext4 $PARTITION4

    #mount partitions
    echo "Mounting Partitions -------------------"
    mount $PARTITION3 /mnt
    mkdir /mnt/home
    mount $PARTITION4 /mnt/home
    swapon $PARTITION2
    
}
set_bootloader(){
    mkdir -p /mnt/boot
    if [ $BOOTLOADER == "systemd" ]; then
        mount $PARTITION1 /mnt/boot
    elif [[ -d "/sys/firmware/efi" ]]; then
        mkdir -p /mnt/boot/efi
        mount $PARTITION1 /mnt/boot/efi
    fi
}
get_hostname(){
    read -rp "Please enter the hostname [test]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-test}
}
set_time(){
    timedatectl set-ntp true
}
setup_pacman(){
    sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ' /etc/pacman.conf
    reflector --save /etc/pacman.d/mirrorlist --country US --protocol https --score 10 --verbose
}
detect_CPU(){
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ $CPU == *"AuthenticAMD"* ]]; then
        BASEINSTALL+="amd-ucode "
    else
        BASEINSTALL+="intel-ucode "
    fi
}
detect_hypervisor(){
    hypervisor=$(systemd-detect-virt)
    HWTYPE="vm"
    case $hypervisor in
        kvm )       
                    BASEINSTALL+="qemu-guest-agent spice-vdagent xf86-video-qxl "
                    SERVICES+="qemu-guest-agent "
                    ;;
        vmware  )   
                    BASEINSTALL+="open-vm-tools "
                    SERVICES+="vmtoolsd vmware-vmblock-fuse "
                    ;;
        oracle )    
                    BASEINSTALL+="virtualbox-guest-utils "
                    SERVICES+="vboxservice "
                    ;;
        microsoft ) 
                    BASEINSTALL+="hyperv "
                    SERVICES+="hv_fcopy_daemon hv_kvp_daemon hv_vss_daemon "
                    ;;
        * )         
                    COREINSTALL+="linux-firmware linux-headers "
                    HWTYPE="metal"
                    ;;
    esac
}
detect_GPU(){
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<< "${gpu_type}"; then
        BASEINSTALL+="nvidia nvidia-settings nvidia-utils "
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        BASEINSTALL+="xf86-video-amdgpu "
    elif grep -E "Integrated Graphics Controller" <<< "${gpu_type}"; then
        BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
    elif grep -E "Intel Corporation UHD" <<< "${gpu_type}"; then
        BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
    fi
}
set_kernel(){
    KERNEL="linux"
}
select_DE(){
    PS3="Select a DE [Server]: "
    select DE in Plasma PlasmaMeta Gnome XFCE i3 Awesome LXQT Server
    do
        DESKTOP=$DE
        break
    done

    #Xorg
    xorg="xorg-server xorg-apps xorg-xinit"

    case $DESKTOP in
        Plasma )    #KDE Plasma
                    APPS+="gwenview okular spectacle elisa kdeconnect kio-extras dolphin ark filelight kate kcalc kcharselect kdialog 
                    konsole kwalletmanager print-manager bluedevil kinfocenter kscreen kwallet-pam oxygen-sounds plasma-desktop 
                    plasma-disks plasma-nm plasma-pa plasma-systemmonitor powerdevil xdg-desktop-portal-kde sddm sddm-kcm ${xorg} "
                    SERVICES+="sddm "
                    ;;
        PlasmaMeta )    #KDE Plasma
                    APPS+="plasma-meta kde-graphics-meta kde-multimedia-meta kde-network-meta kde-system-meta kde-utilities-meta ${xorg} "
                    SERVICES+="sddm "
                    ;;
        Gnome )     #Gnome
                    APPS+="gnome gnome-tweaks gnome-packagekit-plugin ${xorg} "
                    SERVICES+="gdm "
                    ;;
        XFCE )      #XFCE
                    APPS+="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter ${xorg} "
                    SERVICES+="lightdm "
                    ;;
        i3 )        #i3
                    APPS+="i3-wm i3blocks i3lock i3status numlockx lightdm lightdm-gtk-greeter ranger dmenu kitty ${xorg} "
                    APPS+="noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont ttf-liberation ttf-droid ttf-roboto terminus-font "
                    SERVICES+="lightdm "
                    ;;
        Awesome )   #Awesome - wip
                    APPS+="awesome xterm xorg-twm xorg-xclock ${xorg} "
                    ;;
        LXQT )      #LXQT
                    APPS+="lxqt xdg-utils ttf-freefont sddm libpulse libstatgrab libsysstat lm_sensors network-manager-applet oxygen-icons pavucontrol-qt ${xorg} "
                    SERVICES+="sddm "
                    ;;
        Server )    #Server
                    ;;
        "" )        ;;
        * )         ;;
    esac

    PS3="Install Type? [minimal]: "
    select IT in full minimal miniarchvm
    do
        INSTALLTYPE=$IT
        break
    done
}
core_setup(){
    COREINSTALL+="base ${KERNEL} linux-firmware "
    if [ "${INSTALLTYPE}" != "minimal" ]; then
        COREINSTALL+="base-devel "
    fi
}
confirm_settings(){
    echo "confirm"
}
app_setup(){
    
    #General
        APPS+="nano sudo reflector htop git openssh ntp "
        SERVICES+="sshd ntpd "

    if [[ $IT == "full" ]]; then
        #networking
            APPS+="samba cifs-utils nfs-utils ntfs-3g rsync networkmanager "
            SERVICES+="NetworkManager "
    fi
    if [[ $IT == "full" ]] || [[ $IT == "miniarchvm" ]]; then
        
        if [[ $DESKTOP != "Server" ]]; then
            #software
                APPS+="cmus mpv pianobar firefox "
            #Audio
                APPS+="sof-firmware pulseaudio pulseaudio-alsa alsa-utils pavucontrol "
            #General
                APPS+="xdg-user-dirs "
        fi
        if [[ $HWTYPE == "metal" ]]; then
            #Bluetooth
                APPS+="bluez bluez-utils bluedevil pulseaudio-bluetooth "
                SERVICES+="bluetooth "
            #Other Drivers
                APPS+="apcupsd broadcom-wl "
                SERVICES+="apcupsd "
        fi
    fi
}
config_install(){

    genfstab -U /mnt >> /mnt/etc/fstab

    echo "${HOSTNAME}" > /mnt/etc/hostname

    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen

    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    #LANGUAGE
    #LC_ALL
    #LC_MESSAGES

}
install_all(){
    pacstrap /mnt $COREINSTALL $BASEINSTALL $APPS --noconfirm --needed
    systemctl enable $SERVICES --root=/mnt
}
config_system(){
    arch-chroot /mnt /bin/bash -e <<EOF

        #set timezone
        ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

        # Setting up clock.
        echo "Setting up the system clock."
        hwclock --systohc

        #echo "Please set root password."
        echo -e "$PASSWORD1\n$PASSWORD1" | passwd root

        #Create user
        echo "Creating User."
        useradd -m -G wheel $USERNAME
        #Add user to sudoers
        sed -i 's/# %wheel ALL=(ALL/%wheel ALL=(ALL/' /etc/sudoers
        #Set password
        echo -e "$PASSWORD1\n$PASSWORD1" | passwd $USERNAME

EOF
}
bootloader_install(){
    if [[ $BOOTLOADER == "grub" ]]; then
        install_grub_boot
    else
        install_systemd_boot
    fi
}
install_grub_boot(){
    if [[ $UEFI ]]; then

        arch-chroot /mnt /bin/bash -e <<EOF
            grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
            grub-mkconfig -o /boot/grub/grub.cfg 
EOF
    else
        grub-install --boot-directory=/mnt/boot ${DISK}
        arch-chroot /mnt /bin/bash -e <<EOF
            grub-mkconfig -o /boot/grub/grub.cfg
EOF
    fi
}
install_systemd_boot(){
    bootctl --path=/mnt/boot install
    echo -e "default  arch \ntimeout  3 \neditor   no" >> /mnt/boot/loader/loader.conf
    echo -e "title Arch Linux \nlinux /vmlinuz-linux \ninitrd /initramfs-linux.img \noptions root=${PARTITION3} rw" >> /mnt/boot/loader/entries/arch.conf
}

#main --------------------

# detect cpu, gpu, hypervisor
    detect_CPU
    detect_GPU
    detect_hypervisor
# Customize User details, name, pass, hostname
    clear
    show_version
    get_usersetup
    clear
    get_hostname
# pick kernel
    clear
    set_kernel
# Select DE & type (full, min etc for software bundles)
    clear
    select_DE
    app_setup
# Choose bootloader, detect if UEFI or BIOS
    choose_bootloader
# Select disk.
    clear
    get_drive
    calculate_size
    set_partitions
#confirm settings
    clear
    confirm_settings
    clear

#------- all setup done, installing now  -------

# wipe drive, partition disk, format partition, mount partitions
    format_drive
#set bootloader
    set_bootloader
# timedatectl
    set_time
# setup pacman, update, pacstrap, update mirrors etc
    setup_pacman
# core install, Install DE and apps
    core_setup
    install_all
# genfstab, hostname, timezones
    config_install
# arch-chroot, set root, create user
    config_system
# bootloader
    bootloader_install
# reboot
    umount -R /mnt
    reboot
