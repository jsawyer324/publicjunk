#!/bin/sh

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
  nmcli con mod $T ipv4.dns "103.86.96.100, 103.86.99.100"
  nmcli con mod $T ipv6.method "disabled"
done
