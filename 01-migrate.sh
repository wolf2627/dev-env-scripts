#!/bin/bash
# 01-migrate.sh - Handle user migration when DEV_USERNAME changes
# This runs before user setup to migrate data from old users

STORAGE_PATH="/var/labsstorage"
CURRENT_USER_FILE="${STORAGE_PATH}/.current_user"

echo "Checking for user migration..."

# ============================================
# Detect if username has changed
# ============================================
if [ -f "$CURRENT_USER_FILE" ]; then
    OLD_USERNAME=$(cat "$CURRENT_USER_FILE")
    
    if [ "$OLD_USERNAME" != "$DEV_USERNAME" ]; then
        echo "Username change detected: $OLD_USERNAME -> $DEV_USERNAME"
        
        OLD_HOME="${STORAGE_PATH}/home/${OLD_USERNAME}"
        NEW_HOME="${STORAGE_PATH}/home/${DEV_USERNAME}"
        
        # ============================================
        # Migrate home directory
        # ============================================
        if [ -d "$OLD_HOME" ] && [ ! -d "$NEW_HOME" ]; then
            echo "Migrating home directory..."
            mv "$OLD_HOME" "$NEW_HOME"
            echo "✓ Home directory migrated: $OLD_HOME -> $NEW_HOME"
        elif [ -d "$OLD_HOME" ] && [ -d "$NEW_HOME" ]; then
            echo "WARNING: Both old and new home directories exist!"
            echo "  Old: $OLD_HOME"
            echo "  New: $NEW_HOME"
            echo "Manual intervention may be needed."
        fi
        
        # ============================================
        # Fix symlinks that reference old username
        # ============================================
        echo "Updating symlinks..."
        
        # Fix /var/www/html if it points to old user
        if [ -L "/var/www/html" ]; then
            LINK_TARGET=$(readlink /var/www/html)
            if echo "$LINK_TARGET" | grep -q "$OLD_USERNAME"; then
                NEW_TARGET="${STORAGE_PATH}/home/${DEV_USERNAME}/htdocs"
                rm -f /var/www/html
                ln -sfn "$NEW_TARGET" /var/www/html
                echo "✓ Fixed /var/www/html symlink"
            fi
        fi
        
        # Fix Apache sites-available if it points to old user
        if [ -L "/etc/apache2/sites-available" ]; then
            LINK_TARGET=$(readlink /etc/apache2/sites-available)
            if echo "$LINK_TARGET" | grep -q "$OLD_USERNAME"; then
                NEW_TARGET="${STORAGE_PATH}/home/${DEV_USERNAME}/htconfig"
                rm -f /etc/apache2/sites-available
                ln -sfn "$NEW_TARGET" /etc/apache2/sites-available
                echo "✓ Fixed Apache sites-available symlink"
            fi
        fi
        
        # ============================================
        # Update crontab ownership
        # ============================================
        if [ -f "/var/spool/cron/crontabs/${OLD_USERNAME}" ]; then
            mv "/var/spool/cron/crontabs/${OLD_USERNAME}" "/var/spool/cron/crontabs/${DEV_USERNAME}" 2>/dev/null || true
            echo "✓ Migrated crontab"
        fi
        
        # ============================================
        # Clean up old sudoers files
        # ============================================
        rm -f "/etc/sudoers.d/${OLD_USERNAME}"* 2>/dev/null || true
        
        echo "Migration complete!"
    else
        echo "Username unchanged: $DEV_USERNAME"
    fi
else
    echo "First deployment for user: $DEV_USERNAME"
fi

# ============================================
# Save current username for future migrations
# ============================================
echo "$DEV_USERNAME" > "$CURRENT_USER_FILE"
