#!/bin/bash
# 03-user-setup.sh - Create user and configure authentication

echo "Setting up user: ${DEV_USERNAME}"

# Create user with home directory
useradd -m -s /bin/bash "${DEV_USERNAME}" 2>/dev/null || true

# Set user password
echo "${DEV_USERNAME}:${DEV_USER_PASSWORD}" | chpasswd

# Set root password
echo "root:${ROOT_PASSWORD}" | chpasswd

# Add user to sudo group (password required for sudo)
usermod -aG sudo "${DEV_USERNAME}"

# Remove any old NOPASSWD sudoers config
rm -f "/etc/sudoers.d/${DEV_USERNAME}"

# Fix ownership of home directory (handles UID mismatch from persistent storage)
chown -R ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}

# Create .bashrc with nice defaults
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

EOF

chown ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}/.bashrc

echo "User setup complete!"
