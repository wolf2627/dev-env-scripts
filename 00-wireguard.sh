#!/bin/bash
# 00-wireguard.sh - WireGuard VPN Setup and Verification

echo "Setting up WireGuard VPN..."

# Check if WireGuard config exists
if [ ! -f /etc/wireguard/wg0.conf ]; then
    echo "WireGuard config not found at /etc/wireguard/wg0.conf"
    echo "Skipping WireGuard setup..."
    return 0
fi

# Check if config has been filled in (not just template)
if grep -q "YOUR_PRIVATE_KEY_HERE" /etc/wireguard/wg0.conf; then
    echo "ERROR: WireGuard config contains placeholder values."
    echo "Please fill in your actual WireGuard configuration in wireguard.conf"
    exit 1
fi

# Extract DNS from WireGuard config for manual setup
WG_DNS=$(grep -oP '(?<=^DNS\s=\s)[\d\.]+' /etc/wireguard/wg0.conf 2>/dev/null || echo "")

# Create a modified config without DNS line to avoid resolvconf issues
echo "Preparing WireGuard configuration (bypassing resolvconf)..."
grep -v "^DNS" /etc/wireguard/wg0.conf > /tmp/wg0.conf

# Bring up WireGuard interface
echo "Starting WireGuard interface wg0..."
if ! wg-quick up /tmp/wg0.conf; then
    echo "ERROR: Failed to start WireGuard interface"
    exit 1
fi

# Wait for interface to initialize
sleep 2

# Verify WireGuard interface is running
if ! ip link show wg0 &>/dev/null; then
    echo "ERROR: WireGuard interface wg0 failed to start"
    wg-quick down wg0 2>/dev/null || true
    exit 1
fi

# Get WireGuard interface IP and export for other scripts
export WG_IP=$(ip -4 addr show wg0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "WireGuard interface wg0 is up with IP: $WG_IP"

# Manually set DNS if specified
if [ -n "$WG_DNS" ]; then
    echo "Setting DNS to $WG_DNS..."
    echo "nameserver $WG_DNS" > /etc/resolv.conf
fi

# Verify connectivity
echo "Verifying WireGuard connection..."
if [ -n "$WG_IP" ]; then
    echo "✓ WireGuard interface is up with IP: $WG_IP"
    
    if [ -n "$WG_DNS" ]; then
        echo "Testing connectivity to DNS server ($WG_DNS)..."
        if ping -c 2 -W 3 "$WG_DNS" &>/dev/null; then
            echo "✓ Successfully reached DNS server through WireGuard tunnel"
        else
            echo "Note: Could not ping DNS, but interface is up. VPN may still work."
        fi
    fi
else
    echo "ERROR: WireGuard interface has no IP address"
    wg-quick down wg0 2>/dev/null || true
    exit 1
fi

echo ""
echo "WireGuard VPN setup complete!"
