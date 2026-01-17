#!/bin/bash
# 05-ssh-setup.sh - Configure SSH server and keys

echo "Configuring SSH server..."

# Configure sshd - key-based auth only
# PAM handles MOTD and Last Login display (not SSH)
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

# Display - Let PAM handle MOTD and Last Login
X11Forwarding yes
PrintMotd no
PrintLastLog no
UsePAM yes
AcceptEnv LANG LC_*

# Keep alive
ClientAliveInterval 60
ClientAliveCountMax 3

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# ============================================
# Configure PAM for MOTD and Last Login
# ============================================

# Backup original PAM sshd config
cp /etc/pam.d/sshd /etc/pam.d/sshd.backup 2>/dev/null || true

# Create clean PAM sshd config with MOTD and lastlog enabled
cat > /etc/pam.d/sshd << 'PAMEOF'
# PAM configuration for the Secure Shell service

# Standard Un*x authentication.
@include common-auth

# Disallow non-root logins when /etc/nologin exists.
account    required     pam_nologin.so

# Standard Un*x authorization.
@include common-account

# SELinux needs to be the first session rule.
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close

# Set the loginuid process attribute.
session    required     pam_loginuid.so

# Create a new session keyring.
session    optional     pam_keyinit.so force revoke

# Standard Un*x session setup and teardown.
@include common-session

# Print the message of the day upon successful login.
session    optional     pam_motd.so motd=/etc/motd

# Display last login information (AFTER MOTD)
session    optional     pam_lastlog.so showfailed

# Print the status of the user's mailbox upon successful login.
session    optional     pam_mail.so standard noenv

# Set up user limits from /etc/security/limits.conf.
session    required     pam_limits.so

# Read environment variables
session    required     pam_env.so
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale

# SELinux
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open

# Standard Un*x password updating.
@include common-password
PAMEOF

# Create lastlog file for pam_lastlog
touch /var/log/lastlog
chmod 664 /var/log/lastlog
chown root:utmp /var/log/lastlog

# Create wtmp for login tracking
touch /var/log/wtmp
chmod 664 /var/log/wtmp
chown root:utmp /var/log/wtmp

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
