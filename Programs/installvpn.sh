#!/bin/sh

#import vpn
#add creds
#add dns to vpn 103.86.96.100, 103.86.99.100
#change password to everyone
#disable ipv6 on vpn and lan
#set lan to use vpn



sudo pacman -S networkmanager-openvpn network-manager-applet ufw --needed 

sudo ufw enable
sudo ufw default deny outgoing
sudo ufw default deny incoming
sudo ufw allow out on tun0 from any to any

#ip of vpn connection
#Denver us5068
sudo ufw allow out to 212.102.45.12 port 1194 proto udp
sudo ufw allow out from any to 212.102.45.12/24
#Denver us8283
sudo ufw allow out to 212.102.44.56 port 1194 proto udp
sudo ufw allow out from any to 212.102.44.56/24
#Atlanta us8194
sudo ufw allow out to 185.93.0.113 port 1194 proto udp
sudo ufw allow out from any to 185.93.0.113/24
#Atlanta us8203
sudo ufw allow out to 92.119.17.117 port 1194 proto udp
sudo ufw allow out from any to 92.119.17.117/24
#Dallas us8118
sudo ufw allow out to 185.247.70.187 port 1194 proto udp
sudo ufw allow out from any to 185.247.70.187/24
#Dallas us8996
sudo ufw allow out to 209.58.146.171 port 1194 proto udp
sudo ufw allow out from any to 209.58.146.171/24
#StLouis us9436
sudo ufw allow out to 148.72.164.64 port 1194 proto udp
sudo ufw allow out from any to 148.72.164.64/24
#StLouis us9597
sudo ufw allow out to 148.72.165.191 port 1194 proto udp
sudo ufw allow out from any to 148.72.165.191/24



sudo systemctl restart NetworkManager ufw

#possible adds
#sudo ufw allow in on tun0 from any to any
