#!/bin/vbash

source /opt/vyatta/etc/functions/script-template

# System settings
HOSTNAME="vyos-igw"
DEFAULT_GW="192.168.1.1"

# eth0 settings
WAN_IP="192.168.1.10/24"

# eth1 settings
LAN_SUBNET="170.42.0.0/24"
LAN_IP="170.42.0.1/24"

# DNS server settings
DNS_SERVER_LEASE="86400"
DNS_SERVER_START="170.42.0.2"
DNS_SERVER_STOP="170.42.0.254"
DNS_SERVER_DOMAIN_NAME="rancher.internal"

# Backing up current configuration
run show configuration commands > $HOME/$(date +%d%m%Y-%H%M)_${HOSTNAME}.conf

configure
# config {
	set system host-name ${HOSTNAME}
	set system gateway-address "${DEFAULT_GW}"
	set service ssh port "22"

	set interfaces ethernet eth0 address "${WAN_IP}"
	set interfaces ethernet eth0 description 'WAN'

	set interfaces ethernet eth1 address "${LAN_IP}"
	set interfaces ethernet eth1 description 'LAN'

	set nat source rule 100 outbound-interface "${WAN_IP}"
	set nat source rule 100 source address "${LAN_SUBNET}"
	set nat source rule 100 translation address masquerade

	set service dhcp-server disabled 'false'
	set service dhcp-server shared-network-name LAN subnet ${LAN_SUBNET} default-router "${LAN_IP%/*}"
	set service dhcp-server shared-network-name LAN subnet ${LAN_SUBNET} dns-server "${LAN_IP%/*}"
	set service dhcp-server shared-network-name LAN subnet ${LAN_SUBNET} domain-name "${DNS_SERVER_DOMAIN_NAME}"
	set service dhcp-server shared-network-name LAN subnet ${LAN_SUBNET} lease "${DNS_SERVER_LEASE}"
	set service dhcp-server shared-network-name LAN subnet ${LAN_SUBNET} start ${DNS_SERVER_START} stop ${DNS_SERVER_STOP}

	set service dns forwarding system
	set service dns forwarding cache-size '0'
	set service dns forwarding listen-on 'eth1'
	set service dns forwarding name-server "${DEFAULT_GW}"
	set service dns forwarding name-server '8.8.8.8'
# }
commit
save
