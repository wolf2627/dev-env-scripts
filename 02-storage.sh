#!/bin/bash
# 02-storage.sh - Storage Directory Setup and Symlinks

STORAGE_PATH="/var/labsstorage"

echo "Setting up storage directories..."

# Create storage directories
mkdir -p ${STORAGE_PATH}/home
mkdir -p ${STORAGE_PATH}/usr
mkdir -p ${STORAGE_PATH}/projects
mkdir -p ${STORAGE_PATH}/config
mkdir -p ${STORAGE_PATH}/ssh_host_keys

# ============================================
# SSH Host Key Persistence
# ============================================
SSH_HOST_KEYS_DIR="${STORAGE_PATH}/ssh_host_keys"
echo "Setting up persistent SSH host keys..."

if [ -z "$(ls -A $SSH_HOST_KEYS_DIR 2>/dev/null)" ]; then
    echo "First deploy - generating and saving SSH host keys..."
    ssh-keygen -A
    cp /etc/ssh/ssh_host_* "$SSH_HOST_KEYS_DIR/"
else
    echo "Restoring SSH host keys from persistent storage..."
    cp "$SSH_HOST_KEYS_DIR"/ssh_host_* /etc/ssh/
    chmod 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
fi

# ============================================
# Link /home to persistent storage
# ============================================
echo "Setting up persistent /home directory..."

if [ ! -L "/home" ]; then
    rm -rf /home
    ln -sfn ${STORAGE_PATH}/home /home
fi

# Create user home directory
mkdir -p ${STORAGE_PATH}/home/${DEV_USERNAME}

# ============================================
# Create shared directories
# ============================================
mkdir -p /usr/local/kray
ln -sfn ${STORAGE_PATH}/usr /usr/local/kray/shared

# Projects directory
mkdir -p ${STORAGE_PATH}/projects
ln -sfn ${STORAGE_PATH}/projects /home/${DEV_USERNAME}/projects 2>/dev/null || true

echo "Storage setup complete!"
