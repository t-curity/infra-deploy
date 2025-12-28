#!/bin/bash
# ============================================================
# T-curity GPU Server Setup
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=========================================="
echo "T-curity GPU Server Setup"
echo "=========================================="

# NVIDIA 드라이버 확인
if ! command -v nvidia-smi &> /dev/null; then
    err "NVIDIA driver not found!"
    exit 1
fi
log "NVIDIA driver OK"
nvidia-smi --query-gpu=name,driver_version --format=csv

# 시스템 업데이트
log "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Docker 설치
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
fi

# NVIDIA Container Toolkit
if ! command -v nvidia-ctk &> /dev/null; then
    log "Installing NVIDIA Container Toolkit..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

# Docker GPU 테스트
log "Testing Docker GPU..."
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# 모델 디렉토리 생성
log "Creating directories..."
mkdir -p ~/tcurity-ai/{models,data,logs}
mkdir -p ~/tcurity-ai/models/{phase_a,phase_b}
mkdir -p ~/tcurity-ai/data/{images,processed_images}

# 환경 변수 파일
cat > ~/tcurity-ai/.env << 'EOF'
MLFLOW_EXPERIMENT_NAME=captcha-effnet-tracking
IMAGE_DATA_ROOT=/app/data/images
MODEL_OUTPUT_ROOT=/app/models
PHASE_B_PROBLEM_IMAGE_ROOT=/app/data/processed_images
EOF

# 방화벽
log "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 9000/tcp
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
echo "Model Dir: ~/tcurity-ai/models/"
echo "⚠️  모델 파일을 해당 디렉토리에 복사하세요!"
echo "=========================================="
