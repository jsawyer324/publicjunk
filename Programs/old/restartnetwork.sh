#!/bin/sh
sudo hwclock -s  #same as --hwtosys
sudo systemctl restart NetworkManager ufw
