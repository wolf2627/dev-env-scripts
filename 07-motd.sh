#!/bin/bash
# 07-motd.sh - Setup custom Message of the Day

echo "Setting up MOTD..."

# Disable default MOTD scripts
chmod -x /etc/update-motd.d/* 2>/dev/null || true

# Create custom MOTD with colors
# Color codes: \e[0m=reset, \e[1;32m=green, \e[1;36m=cyan, \e[1;33m=yellow, \e[1;35m=magenta
cat > /etc/motd << 'EOF'

 ██ ▄█▀ ██▀███   ▄▄▄     ▓██   ██▓ ▄▄▄▄    ██▓ ███▄    █ 
 ██▄█▒ ▓██ ▒ ██▒▒████▄    ▒██  ██▒▓█████▄ ▓██▒ ██ ▀█   █ 
▓███▄░ ▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░▒██▒ ▄██▒██▒▓██  ▀█ ██▒
▓██ █▄ ▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░▒██░█▀  ░██░▓██▒  ▐▌██▒
▒██▒ █▄░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░░▓█  ▀█▓░██░▒██░   ▓██░
▒ ▒▒ ▓▒░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ░▒▓███▀▒░▓  ░ ▒░   ▒ ▒ 
░ ░▒ ▒░  ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ▒░▒   ░  ▒ ░░ ░░   ░ ▒░
░ ░░ ░   ░░   ░   ░   ▒   ▒ ▒ ░░   ░    ░  ▒ ░   ░   ░ ░ 
░  ░      ░           ░  ░░ ░      ░       ░           ░ 
                          ░ ░           ░        
EOF

# Create dynamic MOTD script with colors and guidelines
cat > /etc/update-motd.d/99-kraybin << 'SCRIPT'
#!/bin/bash

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  🚀 Welcome to Kraybin Atmosphere Development Environment${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}  📊 System Status:${NC}"
echo -e "     • Hostname:  ${BOLD}$(hostname)${NC}"
echo -e "     • Uptime:    $(uptime -p)"
echo -e "     • Memory:    $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo -e "     • Disk:      $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
echo ""

echo -e "${MAGENTA}  🗄️  Available Database Services:${NC}"
echo -e "     • MongoDB:    ${CYAN}mongo.db.local:27017${NC}"
echo -e "     • MySQL:      ${CYAN}mysql.db.local:3306${NC}"
echo -e "     • PostgreSQL: ${CYAN}postgres.db.local:5432${NC}"
echo -e "     • Redis:      ${CYAN}redis.local:6379${NC}"
echo ""

echo -e "${GREEN}  📁 Quick Reference:${NC}"
echo -e "     • Projects:   ${BOLD}~/projects${NC}"
echo -e "     • Web Root:   ${BOLD}~/htdocs${NC} → /var/www/html"
echo -e "     • Apache Cfg: ${BOLD}~/htconfig${NC} → /etc/apache2/sites-available"
echo ""

echo -e "${BLUE}  � Guidelines:${NC}"
echo -e "     ${BOLD}1.${NC} Your home directory persists across container rebuilds"
echo -e "     ${BOLD}2.${NC} Use ${CYAN}sudo a2ensite <site>${NC} to enable Apache sites"
echo -e "     ${BOLD}3.${NC} Use ${CYAN}sudo service apache2 restart${NC} after config changes"
echo -e "     ${BOLD}4.${NC} Node.js is managed via NVM: ${CYAN}nvm install <version>${NC}"
echo -e "     ${BOLD}5.${NC} Crontabs persist: ${CYAN}crontab -e${NC} to edit"
echo -e "     ${BOLD}6.${NC} Password is ${YELLOW}<username>@098${NC} for sudo"
echo ""

echo -e "${RED}  ⚠️  Important:${NC}"
echo -e "     • ${BOLD}DO NOT${NC} store sensitive data outside ~/projects or ~/htdocs"
echo -e "     • Run ${CYAN}kray status${NC} on host to check services"
echo -e "     • VPN must be connected for external access"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
SCRIPT

chmod +x /etc/update-motd.d/99-kraybin

echo "MOTD setup complete!"
