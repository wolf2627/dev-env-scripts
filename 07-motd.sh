#!/bin/bash
# 07-motd.sh - Setup custom Message of the Day

echo "Setting up MOTD..."

# Disable default MOTD scripts (we use static /etc/motd)
chmod -x /etc/update-motd.d/* 2>/dev/null || true
rm -f /etc/update-motd.d/* 2>/dev/null || true

# Get system info for static MOTD
HOSTNAME_VAL=$(hostname)
OS_DESC=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
KERNEL_INFO=$(uname -srm)
WG_IP=$(ip -4 addr show wg0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "N/A")

# Create static MOTD (displayed by SSH's PrintMotd yes)
cat > /etc/motd << EOF

 ██ ▄█▀ ██▀███   ▄▄▄     ▓██   ██▓ ▄▄▄▄    ██▓ ███▄    █ 
 ██▄█▒ ▓██ ▒ ██▒▒████▄    ▒██  ██▒▓█████▄ ▓██▒ ██ ▀█   █ 
▓███▄░ ▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░▒██▒ ▄██▒██▒▓██  ▀█ ██▒
▓██ █▄ ▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░▒██░█▀  ░██░▓██▒  ▐▌██▒
▒██▒ █▄░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░░▓█  ▀█▓░██░▒██░   ▓██░
▒ ▒▒ ▓▒░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ░▒▓███▀▒░▓  ░ ▒░   ▒ ▒
░ ░▒ ▒░  ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ▒░▒   ░  ▒ ░░ ░░   ░ ▒░
░ ░░ ░   ░░   ░   ░   ▒   ▒ ▒ ░░   ░    ░  ▒ ░   ░   ░ ░
░  ░      ░           ░  ░░ ░      ░       ░           ░
                          ░ ░           ░

Welcome to Kraybin Atmosphere Development Environment
Machine Description:  ${OS_DESC} ${KERNEL_INFO}
Hostname:             ${HOSTNAME_VAL}
IP Address:           ${WG_IP}

TERMS AND CONDITIONS
--------------------
1. This environment is for learning, development, and testing purposes only.
2. Your home directory (~/) persists across container rebuilds.
3. Files outside /home will be reset on container rebuild.
4. Use 'sudo a2ensite <site>' to enable Apache sites.
5. Node.js is managed via NVM: 'nvm install <version>'
6. Password for sudo is <username>@098

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
With great power comes great responsibility. Happy coding! 🚀
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

echo "MOTD setup complete!"
