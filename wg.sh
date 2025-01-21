#!/bin/sh
# WireGuard installation script for OpenWRT.
echo 'Starting WireGuard installation script for OpenWRT'

# Step 1: Check for kmod-wireguard and wireguard-tools
if opkg list-installed | grep -q kmod-wireguard; then
    echo -e "\033[0;32m kmod-wireguard is installed. \033[0m"
else
    echo -e "\033[0;31m kmod-wireguard is not installed. Run 'opkg install kmod-wireguard wireguard-tools' to install the package. Exiting. \033[0m"
    exit 1
fi

# Step 2: Generate WireGuard keys
wg_private_key=$(wg genkey)
wg_public_key=$(echo "$wg_private_key" | wg pubkey)
echo -e "\033[0;32m WireGuard keys generated. \033[0m"

# Step 3: Create WireGuard interface in /etc/config/network
if ! grep -q "config interface 'wg0'" /etc/config/network; then
echo "
config interface 'wg0'
    option proto 'wireguard'
    option private_key '$wg_private_key'
    list addresses '10.0.0.1/24'
" >> /etc/config/network
    echo -e '\033[0;32m WireGuard interface added to /etc/config/network \033[0m'
fi

# Step 4: Add a peer configuration
read -p "Enter the public key of the peer: " peer_public_key
read -p "Enter the allowed IPs for the peer (e.g., 10.0.0.2/32): " allowed_ips
read -p "Enter the endpoint of the peer (e.g., vpn.example.com:51820): " endpoint

if ! grep -q "config wireguard_wg0" /etc/config/network; then
echo "
config wireguard_wg0
    option public_key '$peer_public_key'
    list allowed_ips '$allowed_ips'
    option endpoint_host '${endpoint%%:*}'
    option endpoint_port '${endpoint##*:}'
    option persistent_keepalive '25'
" >> /etc/config/network
    echo -e '\033[0;32m Peer configuration added to /etc/config/network \033[0m'
fi

# Step 5: Update firewall rules
if ! grep -q "option name 'wgzone'" /etc/config/firewall; then
echo "
config zone
    option name 'wgzone'
    list network 'wg0'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'

config forwarding
    option src 'lan'
    option dest 'wgzone'
" >> /etc/config/firewall
    echo -e '\033[0;32m Firewall configuration updated \033[0m'
fi

# Step 6: Restart network and firewall
echo 'Restarting Network and Firewall...'
/etc/init.d/network restart
/etc/init.d/firewall restart

echo -e "\033[0;32m WireGuard setup completed successfully. \033[0m"
