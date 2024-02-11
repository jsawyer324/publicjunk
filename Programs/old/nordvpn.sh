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
#us8121 185.247.70.211
#us8118 185.247.70.187
#us8996 185.247.70.211

#Denver
#us9212 
#us9188 
#us9184 
#us8283 212.102.44.56
#us6659 
#us5068 212.102.45.12
#us5085 

#Atlanta
#us8194 185.93.0.113
#us8203 92.119.17.117
