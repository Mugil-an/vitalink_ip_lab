#!/usr/bin/env bash
# =============================================================================
# VitaLink EC2 Instance Setup Script
# =============================================================================
# Run this ONCE on a fresh Ubuntu 22.04/24.04 EC2 instance.
# Usage:
#   chmod +x setup-ec2.sh
#   sudo ./setup-ec2.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[SETUP]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root (use sudo)${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. System updates
# ---------------------------------------------------------------------------
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    htop \
    jq \
    fail2ban

# ---------------------------------------------------------------------------
# 2. Install Docker
# ---------------------------------------------------------------------------
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    systemctl enable docker
    systemctl start docker
    log "Docker installed: $(docker --version)"
else
    log "Docker already installed: $(docker --version)"
fi

# ---------------------------------------------------------------------------
# 3. Install Docker Compose plugin
# ---------------------------------------------------------------------------
if ! docker compose version &> /dev/null; then
    log "Installing Docker Compose plugin..."
    apt-get install -y docker-compose-plugin
    log "Docker Compose installed: $(docker compose version)"
else
    log "Docker Compose already installed: $(docker compose version)"
fi

# ---------------------------------------------------------------------------
# 4. Configure firewall (UFW)
# ---------------------------------------------------------------------------
log "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
log "Firewall configured (SSH, HTTP, HTTPS allowed)"

# ---------------------------------------------------------------------------
# 5. Configure fail2ban for SSH protection
# ---------------------------------------------------------------------------
log "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

systemctl enable fail2ban
systemctl restart fail2ban
log "fail2ban configured"

# ---------------------------------------------------------------------------
# 6. Configure swap (useful for t2.micro/t3.micro)
# ---------------------------------------------------------------------------
if [[ ! -f /swapfile ]]; then
    log "Creating 2GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log "Swap configured"
else
    log "Swap already exists"
fi

# ---------------------------------------------------------------------------
# 7. Set up project directory
# ---------------------------------------------------------------------------
APP_DIR="/opt/vitalink"
log "Setting up application directory at $APP_DIR..."
mkdir -p "$APP_DIR"
chown ubuntu:ubuntu "$APP_DIR"

# ---------------------------------------------------------------------------
# 8. Install Certbot for SSL (optional, run manually)
# ---------------------------------------------------------------------------
log "Installing Certbot for SSL..."
apt-get install -y certbot
log "Certbot installed. To set up SSL later, run:"
log "  sudo certbot certonly --standalone -d your-domain.com"

# ---------------------------------------------------------------------------
# 9. Set up log rotation for Docker
# ---------------------------------------------------------------------------
log "Configuring Docker log rotation..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
systemctl restart docker

# ---------------------------------------------------------------------------
# 10. System tuning
# ---------------------------------------------------------------------------
log "Applying system tuning..."
cat >> /etc/sysctl.conf <<'EOF'

# VitaLink performance tuning
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 65535
EOF
sysctl -p

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
log "============================================="
log "  EC2 Setup Complete!"
log "============================================="
log ""
log "Next steps:"
log "  1. Clone your repo:"
log "     cd /opt/vitalink"
log "     git clone https://github.com/YOUR_USER/VitaLink_Karthi.git ."
log ""
log "  2. Create production env file:"
log "     cp deploy/.env.production.example deploy/.env.production"
log "     nano deploy/.env.production"
log ""
log "  3. Run initial deployment:"
log "     cd deploy"
log "     chmod +x deploy.sh"
log "     ./deploy.sh initial"
log ""
log "  4. (Optional) Set up SSL:"
log "     sudo certbot certonly --standalone -d your-domain.com"
log "     Then uncomment HTTPS block in deploy/nginx/conf.d/default.conf"
log ""
log "============================================="
