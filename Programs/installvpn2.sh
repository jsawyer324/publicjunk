#!/bin/sh

WIRED="Wired connection 1"

PS3="Which vpn would you like to setup: "
select CITY in $(ls -d */)
do
break
done

cd $CITY
for i in $(ls *.ovpn); do nmcli connection import type openvpn file $i; done

for i in $(ls *.ovpn)
do
  T=${i::-5}
  HOSTNAME=${i::-13}
  nmcli con mod $T ipv4.dns "103.86.96.100, 103.86.99.100"
  nmcli con mod $T ipv6.method "disabled"

  IP=$(ping -c1 -t1 -W0 $HOSTNAME 2>&1 | tr -d '():' | awk '/^PING/{print $3}')
  sudo ufw allow out to ${IP} port 1194 proto udp
  sudo ufw allow out from any to ${IP}/24
done

sudo pacman -S networkmanager-openvpn network-manager-applet ufw --needed 

sudo ufw enable
sudo ufw default deny outgoing
sudo ufw default deny incoming
sudo ufw allow out on tun0 from any to any

sudo nmcli con mod ${WIRED} connection.autoconnect yes
sudo nmcli con mod ${WIRED} ipv6.method "disabled"

sudo systemctl restart NetworkManager ufw
