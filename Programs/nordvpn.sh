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
