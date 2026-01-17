#!/bin/bash
# 05-packages.sh - Install development packages

STORAGE_PATH="/var/labsstorage"
MARKER_FILE="${STORAGE_PATH}/.packages_installed"

# Skip if packages already installed (persistence check)
if [ -f "$MARKER_FILE" ]; then
    echo "Packages already installed, skipping..."
    return 0
fi

echo "Installing development packages..."

# ============================================
# Fix locale warnings first
# ============================================
echo "Setting up locales..."
apt-get update
apt-get install -y --no-install-recommends locales apt-utils

# Generate and configure locale
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt-get update

apt-get install -y --no-install-recommends \
    vim \
    netcat-openbsd \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    tmux \
    htop \
    tree \
    jq \
    zip \
    unzip \
    rsync \
    man-db \
    locales \
    gnupg \
    lsb-release \
    wget

# Generate locales
locale-gen en_US.UTF-8 2>/dev/null || true
update-locale LANG=en_US.UTF-8 2>/dev/null || true

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

# Mark as installed
touch "$MARKER_FILE"

echo "Package installation complete!"
