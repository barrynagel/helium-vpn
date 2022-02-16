#!/bin/bash

echo "Current iptables configuration"
iptables -t nat -L

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

echo "iptables flushed"
iptables -t nat -L

