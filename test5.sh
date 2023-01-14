#!/bin/sh

#config ------------------
version="1"
BOOTLOADER="grub" #systemd or grub


#funtions ----------------

usersetup(){

  set_password "PASSWORD"
}

set_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        echo -ne "ERROR! Passwords do not match. \n"
        set_password
    fi
}

#main --------------------

clear

# Get User details, name, pass
# Get hostname
# Select disk.
# Select DE & type (full, min etc for software bundles)
# pick kernel

# detect cpu
# detect gpu
# detect vm

# wipe drive
# partition disk
# format partition
# mount partitions

# timedatectl
# setup pacman, update, pacstrap, update mirrors etc

# core install
# genfstab, hostname, timezones 
# Install DE and apps

# arch-chroot
# bootloader
# set root
# create user

# reboot
