#!/bin/bash
# 03-user-setup.sh - Create user and configure authentication

STORAGE_PATH="/var/labsstorage"

echo "Setting up user: ${DEV_USERNAME}"

# Remove default ubuntu user if exists
userdel -r ubuntu 2>/dev/null || true

# Create user with specific UID 1000
useradd -m -s /bin/bash -u 1000 "${DEV_USERNAME}" 2>/dev/null || true

# Set user password
echo "${DEV_USERNAME}:${DEV_USERNAME}@098" | chpasswd

# Set root password
echo "root:${DEV_USERNAME}@098" | chpasswd

# Add user to groups
usermod -aG sudo "${DEV_USERNAME}"
usermod -aG crontab "${DEV_USERNAME}" 2>/dev/null || true

# Remove any old NOPASSWD sudoers config
rm -f "/etc/sudoers.d/${DEV_USERNAME}"

# ============================================
# Setup user home directory
# ============================================
mkdir -p /home/${DEV_USERNAME}

# Copy skeleton files without overwriting existing
cp --update /etc/skel/.bash_logout /home/${DEV_USERNAME}/.bash_logout 2>/dev/null || true
cp --update /etc/skel/.bashrc /home/${DEV_USERNAME}/.bashrc 2>/dev/null || true
cp --update /etc/skel/.profile /home/${DEV_USERNAME}/.profile 2>/dev/null || true

# Create custom .bashrc if it doesn't exist
if [ ! -f /home/${DEV_USERNAME}/.bashrc ] || [ ! -s /home/${DEV_USERNAME}/.bashrc ]; then
    cat > /home/${DEV_USERNAME}/.bashrc << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Custom prompt
PS1='\[\033[01;32m\]\u@kraybin\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Load NVM if exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

EOF
fi

# ============================================
# Create projects directory
# ============================================
mkdir -p ${STORAGE_PATH}/projects
ln -sfn ${STORAGE_PATH}/projects /home/${DEV_USERNAME}/projects 2>/dev/null || true

# ============================================
# Setup user's init.sh for custom startup commands
# ============================================
if [ ! -f /home/${DEV_USERNAME}/init.sh ]; then
    cat > /home/${DEV_USERNAME}/init.sh << 'EOF'
#!/bin/bash
# User's custom init script
# Add your startup commands here
# This runs on every container start
EOF
    chmod +x /home/${DEV_USERNAME}/init.sh
fi

# Allow user to run their init.sh with sudo
echo "${DEV_USERNAME} ALL=(ALL:ALL) NOPASSWD: /home/${DEV_USERNAME}/init.sh" > /etc/sudoers.d/${DEV_USERNAME}-init
chmod 440 /etc/sudoers.d/${DEV_USERNAME}-init

# ============================================
# Fix ownership
# ============================================
chown ${DEV_USERNAME}:${DEV_USERNAME} ${STORAGE_PATH} 2>/dev/null || true
chown -R ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}

# Fix cron permissions for user
if [ -f /var/spool/cron/crontabs/${DEV_USERNAME} ]; then
    chown ${DEV_USERNAME}:crontab /var/spool/cron/crontabs/${DEV_USERNAME}
    chmod 600 /var/spool/cron/crontabs/${DEV_USERNAME}
fi

# Run user's init.sh
echo "Running user init script..."
su ${DEV_USERNAME} -c "sh /home/${DEV_USERNAME}/init.sh" 2>/dev/null || true

echo "User setup complete!"
