#!/bin/bash
# 02-storage.sh - Storage Directory Setup and Symlinks

STORAGE_PATH="/var/labsstorage"

echo "Setting up storage directories..."

# Create base storage directories
mkdir -p ${STORAGE_PATH}/home
mkdir -p ${STORAGE_PATH}/config
mkdir -p ${STORAGE_PATH}/ssh_host_keys

# ============================================
# Preserve /usr/local to persistent storage
# ============================================
if [ ! -d "${STORAGE_PATH}/usr/local" ]; then
    echo "Preserving /usr/local to persistent storage..."
    mkdir -p ${STORAGE_PATH}/usr
    cp -r /usr/local ${STORAGE_PATH}/usr/
fi

# Relink /usr/local
rm -rf /usr/local
ln -sfn ${STORAGE_PATH}/usr/local /usr/local

# ============================================
# Preserve /var/spool/cron to persistent storage
# ============================================
if [ ! -d "${STORAGE_PATH}/cron" ]; then
    echo "Preserving /var/spool/cron to persistent storage..."
    mkdir -p ${STORAGE_PATH}/cron
    cp -r /var/spool/cron ${STORAGE_PATH}/ 2>/dev/null || mkdir -p ${STORAGE_PATH}/cron/crontabs
fi

# Relink cron
rm -rf /var/spool/cron
ln -sfn ${STORAGE_PATH}/cron /var/spool/cron

# Fix cron permissions
mkdir -p /var/spool/cron/crontabs
chown -R root:crontab /var/spool/cron/crontabs 2>/dev/null || true
chmod -R 1730 /var/spool/cron/crontabs 2>/dev/null || true

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

echo "Storage setup complete!"
