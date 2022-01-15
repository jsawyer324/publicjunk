#!/bin/sh

HOSTNAME="UltraArch2"

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ${HOSTNAME} > /etc/hostname
