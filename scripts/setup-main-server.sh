#!/bin/bash
# ============================================================
# T-curity Main Server Setup
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=========================================="
echo "T-curity Main Server Setup"
echo "=========================================="

# 시스템 업데이트
log "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Docker 설치
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    warn "Docker installed. Re-login required."
else
    log "Docker already installed"
fi

# 디렉토리 생성
log "Creating directories..."
mkdir -p ~/tcurity/{nginx,logs}

# 방화벽 설정
log "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 5173/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

# GHCR 로그인
echo ""
read -p "GHCR 로그인? (y/n): " LOGIN
if [ "$LOGIN" = "y" ]; then
    read -p "GitHub Username: " GH_USER
    read -sp "GitHub Token: " GH_TOKEN
    echo ""
    echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "Public IP: $(curl -s ifconfig.me)"
echo "Private IP: $(hostname -I | awk '{print $1}')"
echo ""
echo "Ports: 8000(Backend), 5173(Demo), 3000(SDK)"
echo "=========================================="
