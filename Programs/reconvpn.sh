#!/bin/bash

vpncon=$(nmcli con show "Wired connection 1" | grep connection.secondaries | awk '{print $2}')
nmcli con down $vpncon
nmcli con up $vpncon
