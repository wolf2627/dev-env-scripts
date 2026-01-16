#!/bin/bash
# 99-finalize.sh - Final setup and display info

echo ""
echo "============================================"
echo "Initialization complete!"

# Get WireGuard IP for display
WG_IP=$(ip -4 addr show wg0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "N/A")

echo "WireGuard IP: $WG_IP"
echo "SSH into container: ssh ${DEV_USERNAME}@${WG_IP}"
echo "============================================"
echo ""
