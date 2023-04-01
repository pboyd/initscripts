#!/bin/bash

set -e
umask 077

# <UDF name="WG_IP" label="WireGuard IP address for the node" example="CIDR notation, e.g. 192.168.50.2/24" />
# <UDF name="WG_PEER_PUBLIC_KEY" label="Public key of the WireGuard peer" example="iupfsx9fgp4erSmjmByPEjAoZPdqNat2Zgq1c5qPwig=" />
# <UDF name="WG_PEER_ALLOWED_IPS" label="Allowed IPs setting of the WireGuard peer" example="192.168.50.1/32" />


# <UDF name="ADMIN_USER" label="Admin username" default="user" example="This is the user you'll log in to manage the host" />

apt-get update
apt-get upgrade -y
apt-get install -y acl wireguard ufw

echo -e "\numask 077" >> /etc/profile

# Make our admin user. Give it root's password and sudo access.
useradd -m -s /bin/bash \
  -G users,sudo \
  -p $(awk -F: '/^root:/ { print $2 }' /etc/shadow) \
  $ADMIN_USER



# Since we have a user account with sudo access, there's no reason to log in to root.
passwd -l root
cat >/etc/ssh/sshd_config.d/01-disable-root.conf <<EOF
PermitRootLogin no
EOF

# To prevent an attacker from inserting their own key into a compromised
# account make it so only root can manage SSH keys.
mkdir -p /etc/ssh/authorized_keys
chmod 0711 /etc/ssh/authorized_keys
cat >/etc/ssh/sshd_config.d/02-system-managed-keys.conf <<EOF
AuthorizedKeysFile /etc/ssh/authorized_keys/%u
EOF

# If the host was configured with an SSH key then assign it to the user and
# disable SSH password logins.
if [ -e "$HOME/.ssh/authorized_keys" ]; then
  mv "$HOME/.ssh/authorized_keys" /etc/ssh/authorized_keys/$ADMIN_USER
  chown root:root /etc/ssh/authorized_keys/$ADMIN_USER
  setfacl -m u:$ADMIN_USER:r /etc/ssh/authorized_keys/$ADMIN_USER
  cat >/etc/ssh/sshd_config.d/03-no-passwords.conf <<EOF
PasswordAuthentication no
EOF
fi

# Activate all our SSH changes.
systemctl restart ssh


# Get a random port number for WireGuard to listen on.
# WireGuard would generate it's own random port every time it starts, but this
# way is consistent.
WG_PORT=$((($SRANDOM % 55536)+10000))

# Generate WireGuard key pair
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/private_key | wg pubkey > /etc/wireguard/public_key

# Configure WireGuard interface with our parameters and generated values.
cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $WG_IP
PrivateKey = $(cat /etc/wireguard/private_key)
ListenPort = $WG_PORT

[Peer]
PublicKey = $WG_PEER_PUBLIC_KEY
AllowedIPs = $WG_PEER_ALLOWED_IPS
EOF

# Start WireGuard via wg-quick and make it permanent.
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0

# Write the connection information to /etc/issue so we can grab the peer
# information from the console.
cat >>/etc/issue <<EOF
[Peer]
PublicKey = $(cat /etc/wireguard/public_key)
AllowedIPs = $(echo $WG_IP | sed 's#/.*#/32#')
Endpoint = $(hostname -I | awk '{ print $1 }'):$WG_PORT
EOF

# Allow anyone to reach the WireGuard port, but require SSH to be on wireguard. 
ufw allow in on eth0 to any port $WG_PORT proto udp
ufw allow in on wg0 to any port 22 proto tcp
ufw enable
