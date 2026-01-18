#!/bin/bash
# 05-ssh-setup.sh - Configure SSH server and keys

echo "Configuring SSH server..."

# Configure sshd - key-based auth only
# PAM handles MOTD, custom script handles Last Login
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

# Display - PAM handles MOTD, custom script handles Last Login
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
# Configure PAM for MOTD only
# Note: pam_lastlog.so was REMOVED in Ubuntu 24.04!
# We use a profile.d script instead for last login
# ============================================

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

# ============================================
# Create custom Last Login script (profile.d)
# This runs AFTER MOTD when bash starts
# ============================================
cat > /etc/profile.d/99-lastlogin.sh << 'LASTLOGINEOF'
#!/bin/bash
# Display last login information (runs after MOTD)
if [ -n "$SSH_CONNECTION" ] && [ -f /var/log/wtmp ]; then
    LAST_LOGIN=$(last -1 -R "$USER" 2>/dev/null | head -1 | grep -v "still logged in" | awk '{print $3, $4, $5, $6, "from", $3}' 2>/dev/null)
    if [ -z "$LAST_LOGIN" ]; then
        # Try alternative format
        LAST_INFO=$(lastlog -u "$USER" 2>/dev/null | tail -1)
        if [ -n "$LAST_INFO" ] && ! echo "$LAST_INFO" | grep -q "Never logged in"; then
            PORT=$(echo "$LAST_INFO" | awk '{print $2}')
            FROM=$(echo "$LAST_INFO" | awk '{print $3}')
            DATE=$(echo "$LAST_INFO" | awk '{print $4, $5, $6, $7, $8}')
            if [ -n "$DATE" ] && [ "$DATE" != "     " ]; then
                echo "Last login: $DATE from $FROM"
            fi
        fi
    fi
fi
LASTLOGINEOF
chmod +x /etc/profile.d/99-lastlogin.sh

# Create lastlog and wtmp files
touch /var/log/lastlog /var/log/wtmp
chmod 664 /var/log/lastlog /var/log/wtmp
chown root:utmp /var/log/lastlog /var/log/wtmp

# Remove Ubuntu legal notice
rm -f /etc/legal 2>/dev/null || true

# ============================================
# SSH Key Setup (supports multiple keys)
# ============================================
SSH_DIR="/home/${DEV_USERNAME}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

# Create .ssh directory
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown -R ${DEV_USERNAME}:${DEV_USERNAME} "$SSH_DIR"

# Handle SSH public keys from environment
# Supports multiple keys separated by semicolons (;)
# Example: SSH_PUBLIC_KEY="ssh-rsa AAA... user1;ssh-ed25519 AAA... user2"
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "Setting up SSH public keys..."
    
    # Create authorized_keys if it doesn't exist
    touch "$AUTHORIZED_KEYS"
    
    # Split by semicolon and process each key
    IFS=';' read -ra KEYS <<< "$SSH_PUBLIC_KEY"
    KEYS_ADDED=0
    
    for KEY in "${KEYS[@]}"; do
        # Trim whitespace
        KEY=$(echo "$KEY" | xargs)
        
        # Skip empty keys
        [ -z "$KEY" ] && continue
        
        # Check if key already exists
        if ! grep -qF "$KEY" "$AUTHORIZED_KEYS" 2>/dev/null; then
            echo "$KEY" >> "$AUTHORIZED_KEYS"
            KEYS_ADDED=$((KEYS_ADDED + 1))
            echo "  ✓ Added key: ${KEY:0:50}..."
        else
            echo "  - Key already exists: ${KEY:0:50}..."
        fi
    done
    
    echo "Total keys added: $KEYS_ADDED"
    
    chmod 600 "$AUTHORIZED_KEYS"
    chown ${DEV_USERNAME}:${DEV_USERNAME} "$AUTHORIZED_KEYS"
else
    echo "WARNING: No SSH_PUBLIC_KEY provided!"
    echo "You will not be able to SSH into the container."
fi

echo "SSH configuration complete!"
