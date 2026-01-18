#!/bin/bash
# 09-apache.sh - Apache web server setup with user htdocs

echo "Setting up Apache web server..."

# ============================================
# Install Apache if not present
# ============================================
if ! command -v apache2 &> /dev/null; then
    echo "Installing Apache..."
    apt-get update
    apt-get install -y --no-install-recommends apache2
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

# ============================================
# Fix Apache ServerName warning
# ============================================
echo "Configuring Apache ServerName..."
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername 2>/dev/null || true

# Add user to www-data group
usermod -aG www-data ${DEV_USERNAME}

# ============================================
# Setup user htdocs and htconfig directories
# ============================================
echo "Setting up user web directories..."

mkdir -p /home/${DEV_USERNAME}/htdocs
mkdir -p /home/${DEV_USERNAME}/htconfig

# Copy default index if htdocs is empty
if [ ! -f /home/${DEV_USERNAME}/htdocs/index.html ]; then
    if [ -f /var/www/html/index.html ]; then
        cp /var/www/html/index.html /home/${DEV_USERNAME}/htdocs/index.html
    else
        cat > /home/${DEV_USERNAME}/htdocs/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Kraybin Atmosphere</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #1a1a2e; color: #eee; }
        h1 { color: #00d4ff; }
    </style>
</head>
<body>
    <h1>🚀 Kraybin Atmosphere</h1>
    <p>Your development environment is running!</p>
</body>
</html>
EOF
    fi
fi

# ============================================
# Link /var/www/html to user htdocs
# ============================================
echo "Linking web root to user htdocs..."

# Configure Apache to follow symlinks and allow access to user htdocs
cat > /etc/apache2/conf-available/htdocs-symlink.conf << EOF
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory /home/${DEV_USERNAME}/htdocs>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF
a2enconf htdocs-symlink 2>/dev/null || true

rm -rf /var/www/html
ln -sfn /home/${DEV_USERNAME}/htdocs /var/www/html

# ============================================
# Preserve and link Apache sites-available
# ============================================
echo "Setting up Apache sites configuration..."

# Copy existing sites to user htconfig (without overwriting)
cp -rn /etc/apache2/sites-available/* /home/${DEV_USERNAME}/htconfig/ 2>/dev/null || true

# Link sites-available to user htconfig
rm -rf /etc/apache2/sites-available
ln -sfn /home/${DEV_USERNAME}/htconfig /etc/apache2/sites-available

# ============================================
# Setup sudoers for Apache commands
# ============================================
echo "Setting up Apache sudo permissions..."
SUDOERS_FILE="/etc/sudoers.d/${DEV_USERNAME}-apache"

cat > ${SUDOERS_FILE} << EOF
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/a2ensite
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/a2dissite
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/a2enmod
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/a2dismod
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/service apache2 *
${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /usr/sbin/apachectl
EOF
chmod 440 ${SUDOERS_FILE}

# ============================================
# Fix ownership and permissions
# ============================================
chown -R ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}/htdocs
chown -R ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}/htconfig

# Allow Apache (www-data) to traverse home directory to reach htdocs
chmod o+x /home/${DEV_USERNAME}

# ============================================
# Start Apache
# ============================================
echo "Starting Apache..."
service apache2 start 2>/dev/null || apache2ctl start || true

echo "Apache setup complete!"
echo "  Web root: /home/${DEV_USERNAME}/htdocs (→ /var/www/html)"
echo "  Sites config: /home/${DEV_USERNAME}/htconfig (→ /etc/apache2/sites-available)"
