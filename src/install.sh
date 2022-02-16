#!/bin/bash

apt update
apt upgrade
apt install iptables dnsutils

wget https://raw.githubusercontent.com/Angristan/openvpn-install/master/openvpn-install.sh -O debian10-vpn.sh

chmod +x debian10-vpn.sh
./debian10-vpn.sh

HOSTNAME=$1
HELIUM_PORT=44158
INTERNAL_IP=10.8.0.2
PUBLIC_IP_ADDR=$(dig +short myip.opendns.com @resolver4.opendns.com)

if [ -n "$HOSTNAME" ]; then
  echo ${HOSTNAME} > /etc/hostname;
  echo "Host name set to '${HOSTNAME}'"
else
  echo -e "Host name variable not supplied ...\n"
fi

iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1240
iptables -A FORWARD -i tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o tun0 -p tcp --syn --dport ${HELIUM_PORT} -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o tun0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A PREROUTING -d ${PUBLIC_IP_ADDR} -p tcp --dport ${HELIUM_PORT} -j DNAT --to-dest ${INTERNAL_IP}:${HELIUM_PORT}
iptables -t filter -A INPUT -p tcp -d ${INTERNAL_IP} --dport ${HELIUM_PORT} -j ACCEPT

echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf

apt-get install iptables-persistent

netfilter-persistent save

./debian10-vpn.sh

sysctl -p
iptables -S
iptables -t nat -L

read -p "Press enter to continue ... server will reboot"

shutdown -r now

