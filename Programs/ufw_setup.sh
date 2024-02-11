#!/bin/bash

ufw --force reset
ufw default deny incoming
ufw default deny outgoing
ufw allow out on tun0
#ufw allow out on eth0 to any port 53,1194 proto udp
ufw allow out 53,1194/udp
ufw allow out to 192.168.1.0/24
ufw enable
ufw status verbose
