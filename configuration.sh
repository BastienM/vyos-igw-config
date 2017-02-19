#!/bin/vbash

source /opt/vyatta/etc/functions/script-template

# System settings
HOSTNAME="kubernetes-igw"
DEFAULT_GW="192.168.1.1"

# eth0 settings
WAN_IP="192.168.1.151/24"

# eth1 settings
LAN_SUBNET="170.42.0.0/24"
LAN_IP="170.42.0.1/24"

# DNS server settings
DNS_SERVER_LEASE="86400"
DNS_SERVER_START="170.42.0.2"
DNS_SERVER_STOP="170.42.0.254"
DNS_SERVER_DOMAIN_NAME="kubernetes.internal"

# Backing up current configuration
run show configuration commands > $HOME/$(date +%d%m%Y-%H%M)_${HOSTNAME}.conf

configure
	set system host-name ${HOSTNAME}
	set system gateway-address "${DEFAULT_GW}"
	set service ssh port "2022"

	set interfaces ethernet eth0 address "${WAN_IP}"
	set interfaces ethernet eth0 description 'WAN'

	set interfaces ethernet eth1 address "${LAN_IP}"
	set interfaces ethernet eth1 description 'LAN'

	set nat source rule 100 outbound-interface "eth0"
	set nat source rule 100 source address "${LAN_SUBNET}"
	set nat source rule 100 protocol "all"
	set nat source rule 100 translation address masquerade

	set nat destination rule 100 description "Port Forward: TCP 22 to Bastion"
	set nat destination rule 100 destination address "${WAN_IP%/*}"
	set nat destination rule 100 destination port "22"
	set nat destination rule 100 inbound-interface "eth0"
	set nat destination rule 100 protocol "tcp"
	set nat destination rule 100 translation address "170.42.0.3"

	set firewall name SSH-TO-LOCAL rule 100 action "accept"
	set firewall name SSH-TO-LOCAL rule 100 description "Allow SSH to internal Bastion"
	set firewall name SSH-TO-LOCAL rule 100 destination address "170.42.0.3"
	set firewall name SSH-TO-LOCAL rule 100 destination port "22"
	set firewall name SSH-TO-LOCAL rule 100 protocol "tcp"

	set nat source rule 210 description "NAT outbound from Bastion"
	set nat source rule 210 source address "170.42.0.3"
	set nat source rule 210 outbound-interface "eth0"
	set nat source rule 210 translation address "192.168.1.151"

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
