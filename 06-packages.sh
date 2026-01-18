#!/bin/bash
# 06-packages.sh - Install development packages

# Check if key packages are already installed (checks actual system state)
check_packages_installed() {
    local packages=("vim" "python3" "tmux" "htop" "jq")
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &>/dev/null; then
            return 1  # Package not installed
        fi
    done
    return 0  # All packages installed
}

# Skip if packages already installed in this container
if check_packages_installed; then
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
    wget \
    nano

# Generate locales
locale-gen en_US.UTF-8 2>/dev/null || true
update-locale LANG=en_US.UTF-8 2>/dev/null || true

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Package installation complete!"
