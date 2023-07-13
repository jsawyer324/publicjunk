#!/bin/sh

for i in $(ls *.ovpn); do nmcli connection import type openvpn file $i; done
#adding dns doesnt seem to work
for i in $(ls *.ovpn); do nmcli con mod $i ipv4.dns "103.86.96.100, 103.86.99.100"; done
