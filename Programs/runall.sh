#!/bin/sh

sh ./setupYay.sh
sh ./installprograms.sh
chmod +x ./restartnetwork.sh
cp ./restartnetwork.sh ~/Desktop

sh ./installvpn2.sh
