#!/bin/bash
# 08-nvm.sh - Install NVM and Node.js LTS

echo "Setting up NVM and Node.js..."

# Skip if NVM already installed and working
if su ${DEV_USERNAME} -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm --version' &>/dev/null; then
    echo "NVM already installed, checking Node.js..."
    if su ${DEV_USERNAME} -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && node --version' &>/dev/null; then
        echo "Node.js already installed, skipping..."
        return 0
    fi
fi

# Add safe directory for git
git config --global --add safe.directory /home/${DEV_USERNAME}/.nvm 2>/dev/null || true

# Clean up any stale locks
rm -f /home/${DEV_USERNAME}/.nvm/.git/shallow.lock 2>/dev/null || true

# Fetch updates if .nvm exists
if [ -d "/home/${DEV_USERNAME}/.nvm" ]; then
    echo "Updating existing NVM installation..."
    su ${DEV_USERNAME} -c "cd /home/${DEV_USERNAME}/.nvm && git fetch" 2>/dev/null || true
fi

# Install NVM
echo "Installing NVM..."
su ${DEV_USERNAME} -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'

# Install Node.js LTS
echo "Installing Node.js LTS..."
su ${DEV_USERNAME} -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts'

# Verify installation
if [ $? -eq 0 ]; then
    echo "✓ Node.js installed successfully"
else
    echo "Node.js installation failed, retrying..."
    rm -rf /home/${DEV_USERNAME}/.nvm
    su ${DEV_USERNAME} -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    su ${DEV_USERNAME} -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts'
fi

# Show installed versions
NODE_VERSION=$(su ${DEV_USERNAME} -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node --version' 2>/dev/null || echo "not installed")
echo "Node.js version: $NODE_VERSION"

echo "NVM setup complete!"
