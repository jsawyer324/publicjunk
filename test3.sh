#!/bin/sh

clear

# Select disk.
echo "Dont be dumb, the disk you choose will be erased!!"
PS3="Select the disk you want to use: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    print "Installing on $DISK"
    break
done

echo $DISK
