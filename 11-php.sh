#!/bin/bash
# 11-php.sh - Install PHP with database extensions (Apache mod_php)

echo "Installing PHP and extensions..."

# Add PHP repository for latest version
add-apt-repository -y ppa:ondrej/php
apt-get update

# Install PHP for Apache (mod_php - runs PHP inside Apache)
# php8.3 pulls common extensions automatically (cli, common, etc.)
apt-get install -y \
    php8.3 \
    libapache2-mod-php8.3 \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-mongodb \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-gd

# Install Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ============================================
# Configure PHP
# ============================================
PHP_CLI_INI="/etc/php/8.3/cli/php.ini"
PHP_APACHE_INI="/etc/php/8.3/apache2/php.ini"

for ini_file in "$PHP_CLI_INI" "$PHP_APACHE_INI"; do
    if [ -f "$ini_file" ]; then
        echo "Configuring $ini_file..."
        
        # Enable short_open_tag
        sed -i 's/^short_open_tag = Off/short_open_tag = On/' "$ini_file"
        sed -i 's/^;short_open_tag = On/short_open_tag = On/' "$ini_file"
        
        # Increase memory limit
        sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$ini_file"
        
        # Increase upload size
        sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 64M/' "$ini_file"
        sed -i 's/^post_max_size = .*/post_max_size = 64M/' "$ini_file"
        
        # Set timezone
        sed -i "s|^;date.timezone =|date.timezone = ${TZ:-UTC}|" "$ini_file"
    fi
done

# ============================================
# Configure Apache for PHP (if Apache exists)
# ============================================
if [ -f /etc/apache2/mods-available/dir.conf ]; then
    echo "Configuring Apache DirectoryIndex..."
    
    # Set index.php before index.html
    cat > /etc/apache2/mods-available/dir.conf << 'DIREOF'
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
DIREOF

    # Enable PHP module for Apache
    a2enmod php8.3 2>/dev/null || true
    
    # Restart Apache if running
    systemctl restart apache2 2>/dev/null || true
fi

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

# Verify installation
echo ""
echo "PHP Installation Summary:"
echo "========================="
php -v | head -1
echo ""
echo "Installed Extensions:"
php -m | grep -iE "(mysql|pgsql|mongodb|curl|mbstring|xml)" | sort
echo ""
echo "Short tags enabled: $(php -r 'echo ini_get("short_open_tag") ? "Yes" : "No";')"
echo ""
echo "Composer version: $(composer --version 2>/dev/null | head -1)"

echo ""
echo "PHP installation complete!"
