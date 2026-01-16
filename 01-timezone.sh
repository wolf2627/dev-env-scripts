#!/bin/bash
# 01-timezone.sh - Timezone Configuration

if [ -n "$TZ" ]; then
    echo "Setting timezone to $TZ..."
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo "$TZ" > /etc/timezone
    echo "Timezone set to $TZ"
else
    echo "No TZ specified, using default UTC"
fi
