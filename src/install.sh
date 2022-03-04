#!/bin/bash

# COLORS
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"

echo -e "${GREEN}Installing helium vpn server ...${ENDCOLOR}"

echo -e "${GREEN}Updating system dependencies ...${ENDCOLOR}"
apt update

echo -e "${GREEN}Upgrading system dependencies ...${ENDCOLOR}"
apt upgrade

echo -e "${GREEN}Installing additional system dependencies ...${ENDCOLOR}"
apt install iptables dnsutils

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HELIUM_PORT=44158
INTERNAL_IP=10.8.0.2
PUBLIC_IP_ADDR=$(dig +short myip.opendns.com @resolver4.opendns.com)

echo -e "${BLUE}System information:${ENDCOLOR}"
echo -e "${BLUE}execution directory: ${__dir}${ENDCOLOR}"
echo -e "${BLUE}hostname: ${HOSTNAME}${ENDCOLOR}"
echo -e "${BLUE}helium port: ${HELIUM_PORT}${ENDCOLOR}"
echo -e "${BLUE}internal ip: ${INTERNAL_IP}${ENDCOLOR}"
echo -e "${BLUE}public ip address: ${PUBLIC_IP_ADDR}${ENDCOLOR}"

echo -e "${GREEN}Setting script permissions ...${ENDCOLOR}"
chmod +x ${__dir}/*.sh

bash ${__dir}/openvpn-install.sh

echo -e "${GREEN}Flushing iptables ...${ENDCOLOR}"
bash ${__dir}/iptables-flush.sh

echo -e "${GREEN}Updating iptables ...${ENDCOLOR}"
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1240
iptables -A FORWARD -i tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o tun0 -p tcp --syn --dport ${HELIUM_PORT} -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o tun0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A PREROUTING -d ${PUBLIC_IP_ADDR} -p tcp --dport ${HELIUM_PORT} -j DNAT --to-dest ${INTERNAL_IP}:${HELIUM_PORT}
iptables -t filter -A INPUT -p tcp -d ${INTERNAL_IP} --dport ${HELIUM_PORT} -j ACCEPT

echo -e "${GREEN}Enabling ipv4 forwarding ...${ENDCOLOR}"
echo 1 > /proc/sys/net/ipv4/ip_forward

echo -e "${GREEN}Enabling persisten iptables ...${ENDCOLOR}"
apt-get install iptables-persistent

netfilter-persistent save

sysctl -p
iptables -S
iptables -t nat -L

echo -e "\n\n\n${GREEN}Installation successful ...${ENDCOLOR}\n\n"
