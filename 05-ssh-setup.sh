#!/bin/bash
# 05-ssh-setup.sh - Configure SSH server and keys

echo "Configuring SSH server..."

# Configure sshd - key-based auth only
# SSH handles MOTD and Last Login display (not PAM)
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

# Display (SSH handles both MOTD and Last Login)
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

# ============================================
# Disable ALL PAM display modules (SSH handles it)
# ============================================
# Disable pam_motd.so - prevents duplicate MOTD
sed -i 's/^session.*pam_motd.so/#&/' /etc/pam.d/sshd 2>/dev/null || true

# Disable pam_lastlog.so - prevents duplicate/conflicting last login
sed -i 's/^session.*pam_lastlog.so/#&/' /etc/pam.d/sshd 2>/dev/null || true
sed -i '/pam_lastlog.so/d' /etc/pam.d/sshd 2>/dev/null || true

# Create lastlog file for SSH's PrintLastLog
touch /var/log/lastlog
chmod 664 /var/log/lastlog
chown root:utmp /var/log/lastlog

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
