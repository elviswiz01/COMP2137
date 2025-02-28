#!/bin/bash

set -e  # Exit on any error

# Function to check if a package is installed
install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo "Installing $1..."
        apt update && apt install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

# Step 1: Configure Network Interface
NETPLAN_CONFIG="/etc/netplan/00-installer-config.yaml"
NEW_IP="192.168.16.21/24"
if [ -f "$NETPLAN_CONFIG" ]; then
    if ! grep -q "$NEW_IP" "$NETPLAN_CONFIG"; then
        echo "Updating network configuration..."
        sed -i "s/addresses: \[.*\]/addresses: [ $NEW_IP ]/g" "$NETPLAN_CONFIG"
        netplan apply
    else
        echo "Network configuration is already correct."
    fi
else
    echo "Netplan configuration file not found. Skipping network configuration."
fi

# Step 2: Update /etc/hosts
HOST_ENTRY="192.168.16.21 server1"
if ! grep -q "^192.168.16.21" /etc/hosts; then
    echo "Updating /etc/hosts..."
    sed -i '/server1/d' /etc/hosts
    echo "$HOST_ENTRY" >> /etc/hosts
else
    echo "/etc/hosts is already correctly configured."
fi

# Step 3: Install Required Software
install_package apache2
install_package squid

# Step 4: Create Users
USERS=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
SSH_DIR=".ssh"
AUTHORIZED_KEYS="authorized_keys"
SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for user in "${USERS[@]}"; do
    if ! id "$user" &>/dev/null; then
        echo "Creating user $user..."
        useradd -m -s /bin/bash "$user"
    else
        echo "User $user already exists."
    fi

    HOME_DIR="/home/$user"
    mkdir -p "$HOME_DIR/$SSH_DIR"
    chmod 700 "$HOME_DIR/$SSH_DIR"
    touch "$HOME_DIR/$SSH_DIR/$AUTHORIZED_KEYS"
    chmod 600 "$HOME_DIR/$SSH_DIR/$AUTHORIZED_KEYS"
    chown -R "$user":"$user" "$HOME_DIR/$SSH_DIR"

    if ! grep -q "$SSH_PUBLIC_KEY" "$HOME_DIR/$SSH_DIR/$AUTHORIZED_KEYS"; then
        echo "Adding SSH key for $user..."
        echo "$SSH_PUBLIC_KEY" >> "$HOME_DIR/$SSH_DIR/$AUTHORIZED_KEYS"
    else
        echo "SSH key already exists for $user."
    fi

done

# Step 5: Configure Sudo for Dennis
if id "dennis" &>/dev/null && ! groups dennis | grep -q sudo; then
    echo "Adding dennis to sudo group..."
    usermod -aG sudo dennis
else
    echo "Dennis already has sudo access."
fi

# Final Output
echo "Script execution completed successfully."
