#!/bin/bash
# 07-services.sh - Start system services (cron, rsyslog, dbus)

echo "Setting up system services..."

# ============================================
# Install services if not present
# ============================================
SERVICES_TO_INSTALL=""

if ! command -v rsyslogd &> /dev/null; then
    SERVICES_TO_INSTALL="$SERVICES_TO_INSTALL rsyslog"
fi

if ! command -v dbus-daemon &> /dev/null; then
    SERVICES_TO_INSTALL="$SERVICES_TO_INSTALL dbus"
fi

if ! command -v cron &> /dev/null; then
    SERVICES_TO_INSTALL="$SERVICES_TO_INSTALL cron"
fi

if [ -n "$SERVICES_TO_INSTALL" ]; then
    echo "Installing services:$SERVICES_TO_INSTALL"
    apt-get update
    apt-get install -y --no-install-recommends $SERVICES_TO_INSTALL
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

# ============================================
# Start D-Bus
# ============================================
echo "Starting D-Bus service..."
service dbus start 2>/dev/null || (mkdir -p /run/dbus && dbus-daemon --system --fork) || true

# ============================================
# Start rsyslog
# ============================================
echo "Starting rsyslog service..."
service rsyslog start 2>/dev/null || rsyslogd || true

# ============================================
# Start cron
# ============================================
echo "Starting cron service..."
service cron start 2>/dev/null || cron || true

echo "System services setup complete!"
