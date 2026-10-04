#!/bin/bash

#config ------------------
VERSION="18"
#FILESYSTEM="ext4"   #not currently used
KERNEL="linux"
TIMEZONE="America/Chicago"
BOOTLOADER="systemd" #systemd or grub
SIZE_SWAP="8G"     #main system
SIZE_ROOT="150G"   #main system
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
SEPERATE_HOME=true
#--------------------------
TESTING=true            #add sleep between commands to slow it down
GREEN='\033[0;32m'      # green color
RED='\033[0;31m'        # red color
NC='\033[0m'            # No Color / Reset



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
    echo "CoreInstall: ${COREINSTALL}"
    echo "BaseInstall: ${BASEINSTALL}"
    echo "Services: ${SERVICES}"
    echo "Apps: ${APPS}"
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
    $TESTING && { echo -e "${GREEN}after format${NC}"; sleep 10; }
#set bootloader
    set_bootloader
# timedatectl
    set_time
# setup pacman, update, pacstrap, update mirrors etc
    setup_pacman
    $TESTING && { echo -e "${GREEN}after setup pacman${NC}"; sleep 10; }
# core install, Install DE and apps
    core_setup
    install_all
    $TESTING && { echo -e "${GREEN}just ran install_all${NC}"; sleep 10; }
# genfstab, hostname, timezones
    config_install
# arch-chroot, set root, create user
    config_system
# bootloader
    bootloader_install
# reboot
    $TESTING && { echo -e "${GREEN}rebooting${NC}"; sleep 10; }
    umount -R /mnt
    reboot

