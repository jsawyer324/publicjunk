#!/bin/sh

sudo pacman -S --needed git wireguard-tools

cd $HOME
git clone https://aur.archlinux.org/nordvpn-bin.bit
cd nordvpn-bin
makepkg -si

sudo groupadd -r nordvpn
sudo gpasswd -a $USER nordvpn

sudo systemctl enable nordvpnd.service
sudo systemctl start nordvpnd.service

sudo usermod -aG nordvpn $USER


#Dallas
#us8121 

#Denver
#us9212 
#us9188 
#us9184 
#us8283 212.102.44.56
#us6659 
#us5068 212.102.45.12
#us5085 

#Atlanta
