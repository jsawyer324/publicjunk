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

