 #!/bin/sh

#screenlayout
xrandr --newmode "1920x1153"  184.75  1920 2048 2248 2576  1153 1156 1166 1196 -hsync +vsync
xrandr --addmode Virtual-1 1920x1153
xrandr --output Virtual-1 --primary --mode 1920x1153 --pos 0x0 --rotate normal
echo "xrandr --output Virtual-1 --primary --mode 1920x1153 --pos 0x0 --rotate normal" >> ~/.profile
echo "xrandr --output Virtual-1 --primary --mode 1920x1153_60.00 --pos 0x0 --rotate normal" >> ~/.bash_profile

#install pacman programs
sudo pacman -S --needed firefox torbrowser-launcher git base-devel networkmanager-openvpn network-manager-applet ufw cifs-utils --noconfirm

#setup yay
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf ./yay-bin

#install yay programs
yay -S --noconfirm brave-bin session-desktop-bin --needed

#install vpn
WIRED="Wired connection 1"

PS3="Which vpn would you like to setup: "
select CITY in $(ls -d1 */)
do
break
done

cd "$CITY" || exit

for i in *.ovpn; do nmcli connection import type openvpn file "$i"; done

for i in *.ovpn
do
  [[ -e "$i" ]] || break
  T=${i::-5}
  HOSTNAME=${i::-13}
  nmcli con mod "$T" ipv4.dns "103.86.96.100, 103.86.99.100"
  nmcli con mod "$T" ipv6.method "disabled"

  IP=$(ping -c1 -t1 -W0 "$HOSTNAME" 2>&1 | tr -d '():' | awk '/^PING/{print $3}')
  sudo ufw allow out to "${IP}" port 1194 proto udp
  sudo ufw allow out from any to "${IP}"/24
done
cd ..

sudo nmcli con mod "${WIRED}" connection.autoconnect yes
sudo nmcli con mod "${WIRED}" ipv6.method "disabled"

sudo systemctl restart NetworkManager

#set route
echo 'ip route add 192.168.1.0/24 via 10.0.2.2' | sudo tee -a /etc/NetworkManager/dispatcher.d/10-routes.sh
sudo chmod +x /etc/NetworkManager/dispatcher.d/10-routes.sh
sudo systemctl enable NetworkManager-dispatcher

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow out on tun0
sudo ufw allow out 53,1194/udp
sudo ufw allow out to 192.168.1.0/24
sudo ufw enable
sudo ufw status verbose

#add alias
chmod +x ./reconvpn.sh
cp ./reconvpn.sh ~/Documents/
echo "alias reconvpn='~/Documents/reconvpn.sh'" >> ~/.bashrc

# pre setup files
mkdir ~/nas
touch ~/.creds
sudo chmod 600 ~/.creds

#cleanup
sudo pacman -Sc --noconfirm;yay --aur -Sc --noconfirm
