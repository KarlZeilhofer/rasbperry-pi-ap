#! /bin/bash

# script is according to totirial on thepi.io
# https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point/

echo Raspberry WiFi Access Point
echo "==========================="
echo
echo This script configures your Raspberry Pi OS to act as an access point. 
echo

echo Enter the WiFi Name 
echo Hit Enter to use default: RaspberryPi-AP
read wifiname
if [ -z "$wifiname" ]; then
	wifiname="RaspberryPi-AP"
fi
echo "Using WiFi name (SSID): ${wifiname}"

echo Enter the WiFi password 
read password
echo "Using WiFi password: ${password}"

# do not modify this, otherwise the dhcp-range 
# in step 4 could be in the wrong subnet
ipaddress="10.0.0.99"
echo "Using IP address ${ipaddress}"


# Step 1:
sudo apt update
sudo apt upgrade

# Step 2:
sudo apt-get install hostapd
sudo apt-get install dnsmasq
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Step 3: 
sudo echo "interface wlan0" >> /etc/dhcpcd.conf
sudo echo "static ip_address=${ipaddress}/24" >> /etc/dhcpcd.conf
sudo echo "denyinterfaces eth0" >> /etc/dhcpcd.conf
sudo echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

# Step 4:
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo echo "interface=wlan0" >> /etc/dnsmasq.conf
sudo echo "  dhcp-range=10.0.0.11,10.0.0.30,255.255.255.0,24h" >> /etc/dnsmasq.conf

# Step 5:
sudo echo "interface=wlan0" >> /etc/hostapd/hostapd.conf
sudo echo "bridge=br0" >> /etc/hostapd/hostapd.conf
sudo echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
sudo echo "channel=7" >> /etc/hostapd/hostapd.conf
sudo echo "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
sudo echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
sudo echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
sudo echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
sudo echo "wpa=2" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
sudo echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
sudo echo "ssid=${wifiname}" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_passphrase=${password}" >> /etc/hostapd/hostapd.conf

sudo echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

# Step 6:
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Step 7:
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

# insert line 
# iptables-restore < /etc/iptables.ipv4.nat
# before exit 0
sudo cp /etc/rc.local /etc/rc.local.backup
sudo sed '/^exit 0.*/i iptables-restore < /etc/iptables.ipv4.nat ' /etc/rc.local > /etc/rc.local

# Step 8
sudo apt-get install bridge-utils
sudo brctl addbr br0
sudo brctl addif br0 eth0

sudo cat "auto br0" >> /etc/network/interfaces
sudo cat "iface br0 inet manual" >> /etc/network/interfaces
sudo cat "bridge_ports eth0 wlan0" >> /etc/network/interfaces

# Step 9
echo System will be restarted in 10 seconds
sleep 10
sudo reboot


