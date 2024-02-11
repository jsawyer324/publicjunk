#!/bin/sh

sh ./setupYay.sh
sh ./installprograms.sh
sh ./installvpn2.sh

echo 'ip route add 192.168.1.0/24 via 10.0.2.2' | sudo tee -a /etc/NetworkManager/dispatcher.d/10-routes.sh
sudo systemctl enable NetworkManager-dispatcher

sudo sh ./ufw_setup.sh

chmod +x ./reconvpn.sh
cp ./reconvpn.sh ~/Documents/
echo "alias reconvpn='~/Documents/reconvpn.sh'" >> ~/.bashrc
