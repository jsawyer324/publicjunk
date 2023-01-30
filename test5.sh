#!/bin/bash

#config ------------------
VERSION="13"
FILESYSTEM="ext4"
KERNEL="linux"
BOOTLOADER="systemd" #systemd or grub


#funtions ----------------
version(){
    echo "Version "$VERSION
}
usersetup(){
    read -rp "Enter new username [james]:" USERNAME
    USERNAME=${USERNAME:-james}
    set_password "PASSWORD"
}
set_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" != "$PASSWORD2" ]]; then
        echo -ne "ERROR! Passwords do not match. \n"
        set_password
    fi
}
set_drive(){
    echo "Dont be dumb, the disk you choose will be erased!!"
    PS3="Select the disk you want to use: "
    select ENTRY in $(lsblk -dpno NAME|grep -P "/dev/sd|nvme|vd");
    do
        DISK=${ENTRY}
        break
    done
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
    sgdisk -n 1::+1G "${DISK}" -t 1:ef00
    sgdisk -n 2::+4G "${DISK}" -t 2:8200
    sgdisk -n 3::+10G "${DISK}"
    sgdisk -n 4:: "${DISK}"

    #format partition
    echo "Formatting Paritions -------------------"
    mkfs.vfat -F32 $PARTITION1
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
    if [ $BOOTLOADER == "systemd" ]; then
    mkdir -p /mnt/boot
    mount $PARTITION1 /mnt/boot
    APPS+="bootctl "
    SERVICES+="systemd-boot-update "
    elif [ $BOOTLOADER == "grub" ]; then
    mkdir -p /mnt/boot/efi
    mount $PARTITION1 /mnt/boot/efi
    APPS+="efibootmgr grub "
    fi
}
set_hostname(){
    read -rp "Please enter the hostname [test]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-test}
}
set_time(){
    timedatectl set-ntp true
}
uefi_check(){
    if [[ -d "/sys/firmware/efi" ]]; then
        UEFI=true
    fi
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
    case $hypervisor in
        kvm )       
                    BASEINSTALL+="qemu-guest-agent spice-vdagent "
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
                    COREINSTALL+="linux-firmware "
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

    PS3="Select a DE: "
    select DE in Plasma Gnome XFCE i3 Awesome LXQT Server
    do
        DESKTOP=$DE
        break
    done

    #Xorg
    xorg="xorg-server xorg-apps xorg-xinit "

    case $DESKTOP in
        Plasma )    #KDE Plasma
                    APPS+="plasma-meta kde-graphics-meta kde-multimedia-meta kde-network-meta kde-system-meta kde-utilities-meta "
                    APPS+=$xorg
                    SERVICES+="sddm "
                    ;;
        Gnome )     #Gnome
                    APPS+="gnome gnome-tweaks gnome-packagekit-plugin "
                    APPS+=$xorg
                    SERVICES+="gdm "
                    ;;
        XFCE )      #XFCE
                    APPS+="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter "
                    APPS+=$xorg
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

    PS3="Install Type? : "
    select IT in full minimal miniarchvm
    do
        INSTALLTYPE=$IT
        break
    done
}
core_setup(){

    COREINSTALL+="base ${KERNEL} "
    if [ "${INSTALLTYPE}" != "minimal" ]; then
        COREINSTALL+="base-devel "
    fi
}
app_setup(){

    APPS+="nano sudo reflector htop git openssh ntp "
    SERVICES+="sshd ntpd "

    #networking
    APPS+="samba cifs-utils nfs-utils ntfs-3g rsync networkmanager "
    SERVICES+="NetworkManager "

    #Other Drivers
    #APPS+="apcupsd broadcom-wl "

    #software
    APPS+="cmus mpv pianobar firefox "

    #Audio
    APPS+="sof-firmware pulseaudio pulseaudio-alsa alsa-utils pavucontrol "

    #Bluetooth
    APPS+="bluez bluez-utils bluedevil pulseaudio-bluetooth "
    SERVICES+="bluetooth "


}
core_install(){
    echo $COREINSTALL
    pacstrap /mnt $COREINSTALL --noconfirm --needed
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

    ln -sf /mnt/usr/share/zoneinfo/America/Chicago /mnt/etc/localtime

}
base_install(){
    echo $BASEINSTALL
    pacstrap /mnt $BASEINSTALL --noconfirm --needed
    echo "${APPS}"
    pacstrap /mnt $APPS --noconfirm --needed
    systemctl enable $SERVICES --root=/mnt
}
config_system(){
    arch-chroot /mnt /bin/bash -e <<EOF

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
        echo "Configuring Grub."
        grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/efi --recheck
        grub-mkconfig -o /boot/grub/grub.cfg

EOF
    fi
}
install_systemd_boot(){
    if [[ $UEFI ]]; then
            echo "Configuring Systemd-boot."
            bootctl --path=/mnt/boot install
            echo -e "default  arch \ntimeout  5 \neditor   no" >> /mnt/boot/loader/loader.conf
            echo -e "title Arch Linux \nlinux /vmlinuz-linux \ninitrd /initramfs-linux.img \noptions root=${PARTITION3} rw" >> /mnt/boot/loader/entries/arch.conf
    fi
}

#main --------------------

# Get User details, name, pass
    clear
    version
    usersetup
# Get hostname
    clear
    set_hostname
# pick kernel
    clear
    set_kernel
# Select DE & type (full, min etc for software bundles)
    clear
    select_DE
# detect if UEFI or BIOS
    uefi_check
# detect cpu
    detect_CPU
# detect gpu
    detect_GPU
# detect vm
    detect_hypervisor
# Select disk.
    clear
    set_drive
    set_partitions
# wipe drive, partition disk, format partition, mount partitions
    format_drive
    #sleep 10
#set bootloader
    set_bootloader
    #sleep 10
# timedatectl
    set_time
# setup pacman, update, pacstrap, update mirrors etc
    setup_pacman
# core install
    core_setup
    app_setup
    core_install
    #sleep 10
# genfstab, hostname, timezones
    config_install
# Install DE and apps
    base_install
    #sleep 10
# arch-chroot
# set root
# create user
    config_system
# bootloader
    bootloader_install
# reboot
    #umount -R /mnt
    #reboot