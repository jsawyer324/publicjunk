#!/bin/bash

#config ------------------
VERSION="9"
#FILESYSTEM="ext4"   #not currently used
KERNEL="linux"
TIMEZONE="America/Chicago"
BOOTLOADER="systemd" #systemd or grub
SIZE_SWAP="8G"     #main system
SIZE_ROOT="100G"   #main system
#SIZE_SWAP="2G"     #custom
#SIZE_ROOT="15G"   #custom
SIZE_MBR="1G"       #MBR size
SIZE_ESP="1G"       #ESP - EFI System Partition
MINIARCH_SIZE_SWAP="2G"                 #miniarchvm size override
MINIARCH_SIZE_ROOT="15G"                #miniarchvm size override
MOBILEARCH_SIZE_SWAP="8G"               #mobilarch
MOBILEARCH_SIZE_ROOT="40G"              #mobilearch
SERVICES=""
APPS=""
AUDIO="pipewire"                        #pulse or pipewire
xorg="xorg-server xorg-apps xorg-xinit" #Xorg
SEPERATE_HOME=false


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

    if [[ -z $DISK ]]; then            #if disk is unset, choose disk
        lsblk -dpno NAME,MODEL
        echo -ne "\nDont be dumb, the disk you choose will be erased!!\n\n"
        PS3="Select the disk you want to use: "
        select ENTRY in $(lsblk -dpno NAME|grep -P "/dev/sd|nvme|vd");
        do
            DISK=${ENTRY}
            break
        done
    fi
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
    X=''
    if [[ "${DISK}" =~ "nvme" ]]; then X='p'; fi
    PARTITION1=${DISK}${X}1
    PARTITION2=${DISK}${X}2
    PARTITION3=${DISK}${X}3
    if [ "$SEPERATE_HOME" = true ]; then
        PARTITION4=${DISK}${X}4
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
    if [ "$SEPERATE_HOME" = true ]; then
        sgdisk -n 3::+"${SIZE_ROOT}" "${DISK}"
        sgdisk -n 4:: "${DISK}"
    else
        sgdisk -n 3:: "${DISK}"
    fi

    #format partition
    echo "Formatting Paritions -------------------"
    if [[ -d "/sys/firmware/efi" ]]; then
        mkfs.vfat -F32 $PARTITION1
    fi
    mkswap $PARTITION2
    yes | mkfs.ext4 $PARTITION3
    if [ "$SEPERATE_HOME" = true ]; then
        yes | mkfs.ext4 $PARTITION4
    fi

    #mount partitions
    echo "Mounting Partitions -------------------"
    mount $PARTITION3 /mnt
    if [ "$SEPERATE_HOME" = true ]; then
        mkdir /mnt/home
        mount $PARTITION4 /mnt/home
    fi
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

    pacman-key --init
    pacman-key --populate

    sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ' /etc/pacman.conf
    #reflector --save /etc/pacman.d/mirrorlist --country 'United States' --latest 10 --sort rate --verbose

    pacman -Sy archlinux-keyring --noconfirm
    pacman -Syy

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
    gpu="none"
    if grep -E "NVIDIA|GeForce" <<< "${gpu_type}"; then
        gpu="nvidia"
        BASEINSTALL+="nvidia-open nvidia-settings nvidia-utils "
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        gpu="amd"
        BASEINSTALL+="xf86-video-amdgpu "
    elif grep -E "Integrated Graphics Controller" <<< "${gpu_type}"; then
        gpu="intel 1"
        BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
    elif grep -E "Intel Corporation UHD" <<< "${gpu_type}"; then
        gpu="intel 2"
        BASEINSTALL+="libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa "
    fi
}
set_kernel(){
    KERNEL="linux"
}
select_HWTYPE(){

    PS3="Install Type? [minimal]: "
    select IT in full minimal miniarchvm mobilearch miniarchcustom
    do
        INSTALLTYPE=$IT
        break
    done

    if [[ $INSTALLTYPE == "miniarchvm" ]]; then
        DISK="/dev/vda"
        SIZE_SWAP=$MINIARCH_SIZE_SWAP
        SIZE_ROOT=$MINIARCH_SIZE_ROOT
    elif [[ $INSTALLTYPE == "mobilearch" ]]; then
        SIZE_SWAP=$MOBILEARCH_SIZE_SWAP
        SIZE_ROOT=$MOBILEARCH_SIZE_ROOT
    elif [[ $INSTALLTYPE == "miniarchcustom" ]]; then

        SIZE_SWAP=$MINIARCH_SIZE_SWAP
        SIZE_ROOT=$MINIARCH_SIZE_ROOT
    fi

}
select_DE(){
   
    



    if [[ $INSTALLTYPE == "miniarchvm" ]]; then
    
        DESKTOP="XFCE"
        APPS+="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter noto-fonts ${xorg} "
        SERVICES+="lightdm "
    
    else
        PS3="Select a DE [Server]: "
        select DE in Plasma PlasmaMeta Plasma6 Gnome XFCE i3 Awesome LXQT Hyprland Server
        do
            DESKTOP=$DE
            break
        done
    
    
        case $DESKTOP in
            Plasma )    #KDE Plasma
                        APPS+="gwenview okular spectacle elisa kdeconnect kio-extras dolphin ark filelight kate kcalc kcharselect kdialog 
                        konsole kwalletmanager print-manager kinfocenter kscreen kwallet-pam oxygen-sounds plasma-desktop 
                        plasma-disks plasma-nm plasma-pa plasma-systemmonitor powerdevil xdg-desktop-portal-kde sddm sddm-kcm ${xorg} "
                        SERVICES+="sddm "
                        ;;
            PlasmaMeta )    #KDE Plasma
                        APPS+="plasma-meta kde-graphics-meta kde-multimedia-meta kde-network-meta kde-system-meta kde-utilities-meta ${xorg} "
                        SERVICES+="sddm "
                        ;;
            Plasma6 )    #KDE Plasma
                        APPS+="gwenview okular spectacle kdeconnect dolphin ark filelight kate kcalc kcharselect kdialog 
                        konsole kwalletmanager plasma-nm "
                        APPS+="plasma-meta ${xorg} "
                        SERVICES+="sddm "
                        ;;
            Gnome )     #Gnome
                        APPS+="gnome gnome-tweaks gnome-packagekit-plugin ${xorg} "
                        SERVICES+="gdm "
                        ;;
            XFCE )      #XFCE
                        APPS+="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter noto-fonts ${xorg} "
                        SERVICES+="lightdm "
                        ;;
            i3 )        #i3
                        APPS+="i3-wm i3blocks i3lock i3status numlockx lightdm lightdm-gtk-greeter ranger dmenu kitty polybar rofi ${xorg} "
                        APPS+="noto-fonts noto-fonts-emoji ttf-ubuntu-font-family ttf-dejavu ttf-freefont ttf-liberation ttf-droid ttf-roboto terminus-font "
                        SERVICES+="lightdm "
                        ;;
            Awesome )   #Awesome - wip
                        APPS+="awesome xterm xorg-twm xorg-xclock ${xorg} "
                        ;;
            LXQT )      #LXQT
                        APPS+="lxqt xdg-utils ttf-freefont sddm libpulse libstatgrab libsysstat lm_sensors network-manager-applet oxygen-icons pavucontrol-qt ${xorg} "
                        SERVICES+="sddm "
                        ;;
            Hyperland ) #Hyprland
                        APPS+="hyprland lemurs "
                        APPS+="noto-fonts noto-fonts-emoji noto-fonts-extra noto-fonts-cjk "
                        SERVICES+="lemurs "
                        ;;
            Server )    #Server
                        ;;
            "" )        ;;
            * )         ;;
        esac
    fi
}
core_setup(){
    COREINSTALL+="base ${KERNEL} linux-firmware "
    if [ "${INSTALLTYPE}" != "minimal" ]; then
        COREINSTALL+="base-devel "
    fi
}
app_setup(){
    #HWTYPE: vm or metal
    #IT: full minimal miniarchvm
    #DESKTOP: DE
    
    #General
        APPS+="nano sudo reflector htop git openssh ntp networkmanager "
        SERVICES+="sshd ntpd NetworkManager "

    if [[ $IT == "minimal" ]]; then
        return "$TRUE"
    fi
    if [[ $IT == "full" ]]; then
        #networking
            APPS+="samba cifs-utils nfs-utils ntfs-3g rsync "
    fi
    if [[ $DESKTOP == "Server" ]]; then
        return "$TRUE"
    fi
    if [[ $IT == "miniarchvm" ]]; then
        APPS+="networkmanager-openvpn network-manager-applet ufw pacman-contrib noto-fonts-emoji noto-fonts-cjk noto-fonts-extra "
    fi
    #software
        APPS+="cmus mpv pianobar firefox "
    #General
        APPS+="xdg-user-dirs "
        
    if [[ $AUDIO == "pulse" ]]; then
        #Audio - pulseaudio
        APPS+="sof-firmware pulseaudio pulseaudio-alsa alsa-utils pulseaudio-bluetooth pavucontrol "
    else
        #Audio - pipewire
        APPS+="sof-firmware pipewire pipewire-pulse pipewire-audio pipewire-alsa pavucontrol wireplumber "
    fi

    if [[ $HWTYPE == "metal" ]]; then
        #Bluetooth
            APPS+="bluez bluez-utils bluedevil "
            SERVICES+="bluetooth "
        #Other Drivers
            APPS+="apcupsd broadcom-wl "
            SERVICES+="apcupsd "
    fi
    
}
config_install(){

    genfstab -U /mnt >> /mnt/etc/fstab

    echo "${HOSTNAME}" > /mnt/etc/hostname

    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen

    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

}
install_all(){

    echo $COREINSTALL
    echo "${COREINSTALL}"
    sleep 20

    pacstrap -K /mnt $COREINSTALL --noconfirm --needed
    # sleep 10
    pacstrap -K /mnt $BASEINSTALL --noconfirm --needed
    # sleep 10
    pacstrap -K /mnt $APPS --noconfirm --needed
    # sleep 10
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
    echo "Installing GRUB -------------------"
    if [[ $UEFI ]]; then

        arch-chroot /mnt /bin/bash -e <<EOF
            grub-install --target=x86_64-efi  --bootloader-id=${HOSTNAME} --efi-directory=/boot/efi --recheck
            grub-mkconfig -o /boot/grub/grub.cfg 
EOF
    else
        grub-install --boot-directory=/mnt/boot "${DISK}"
        arch-chroot /mnt /bin/bash -e <<EOF
            grub-mkconfig -o /boot/grub/grub.cfg
EOF
    fi
}
install_systemd_boot(){
    echo "Installing Systemd boot -------------------"
    bootctl --path=/mnt/boot install
    echo -e "default  arch \ntimeout  3 \neditor   no" >> /mnt/boot/loader/loader.conf
    echo -e "title ${HOSTNAME} \nlinux /vmlinuz-linux \ninitrd /initramfs-linux.img \noptions root=${PARTITION3} rw" >> /mnt/boot/loader/entries/arch.conf
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
# select hardware type
    clear
    select_HWTYPE
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
    echo "username: ${USERNAME}"
    echo "hostname: ${HOSTNAME}" 
    echo "disk: ${DISK}"
    echo "swap size: ${SIZE_SWAP}"
    echo "root size: ${SIZE_ROOT}"
    echo "install type: ${IT}"
    echo "DE: ${DESKTOP}"
    echo "gpu type: ${gpu}"
    echo "hypervisor: ${hypervisor}"
    echo "HWTYPE: ${HWTYPE}"
    echo "BOOTLOADER: ${BOOTLOADER}"
    echo "Seperate Home: ${SEPERATE_HOME}"
    echo -e "\n\n"

    read -r -p "${1:-Are you sure you want to continue? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            ;;
        *)
            exit 0
            ;;
    esac
    clear

#------- all setup done, installing now  -------

# wipe drive, partition disk, format partition, mount partitions
    format_drive
    #sleep 30
#set bootloader
    set_bootloader
# timedatectl
    set_time
# setup pacman, update, pacstrap, update mirrors etc
    setup_pacman
    # sleep 10
# core install, Install DE and apps
    core_setup
    install_all
    # sleep 10
# genfstab, hostname, timezones
    config_install
# arch-chroot, set root, create user
    config_system
# bootloader
    bootloader_install
# reboot
    #sleep 2
    umount -R /mnt
    reboot
