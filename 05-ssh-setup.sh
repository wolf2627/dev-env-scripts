#!/bin/bash
# 04-ssh-setup.sh - Configure SSH server and keys

echo "Configuring SSH server..."

# Configure sshd - key-based auth only
cat > /etc/ssh/sshd_config << 'EOF'
# Kraybin Atmosphere SSH Configuration

Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Authentication - Key-based only, no passwords
PermitRootLogin prohibit-password
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Security
MaxAuthTries 6
MaxSessions 10
LoginGraceTime 120

# Features
X11Forwarding yes
PrintMotd yes
PrintLastLog yes
UsePAM yes
AcceptEnv LANG LC_*

# Keep alive
ClientAliveInterval 60
ClientAliveCountMax 3

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Disable PAM MOTD to prevent duplicate display (SSH handles it via PrintMotd)
sed -i 's/^session.*pam_motd.so/#&/' /etc/pam.d/sshd 2>/dev/null || true

# Add pam_lastlog for "Last login" display if not present
if ! grep -q "pam_lastlog.so" /etc/pam.d/sshd; then
    echo "session    optional     pam_lastlog.so" >> /etc/pam.d/sshd
fi

# Create lastlog file if it doesn't exist
touch /var/log/lastlog
chmod 664 /var/log/lastlog

# Remove Ubuntu legal notice
rm -f /etc/legal 2>/dev/null || true

# ============================================
# SSH Key Setup
# ============================================
SSH_DIR="/home/${DEV_USERNAME}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

# Create .ssh directory
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown -R ${DEV_USERNAME}:${DEV_USERNAME} "$SSH_DIR"

# Handle SSH public key from environment
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "Setting up SSH public key..."
    
    if [ -f "$AUTHORIZED_KEYS" ]; then
        if ! grep -qF "$SSH_PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
            echo "$SSH_PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
            echo "SSH key added to authorized_keys"
        else
            echo "SSH key already exists in authorized_keys"
        fi
    else
        echo "$SSH_PUBLIC_KEY" > "$AUTHORIZED_KEYS"
        echo "Created authorized_keys with SSH key"
    fi
    
    chmod 600 "$AUTHORIZED_KEYS"
    chown ${DEV_USERNAME}:${DEV_USERNAME} "$AUTHORIZED_KEYS"
else
    echo "WARNING: No SSH_PUBLIC_KEY provided!"
    echo "You will not be able to SSH into the container."
fi

echo "SSH configuration complete!"
