#!/bin/bash
# ============================================================
# T-curity Manual Deploy Script
# ============================================================
# Usage: ./deploy.sh [all|backend|ai|sdk|demo|redis]
# ============================================================
set -e

# 설정 - AWS 테스트
REGISTRY="ghcr.io"
ORG="t-curity"
MAIN_HOST="43.201.104.130"
GPU_HOST="43.203.216.206"
GPU_PRIVATE="10.0.83.190"
SSH_USER="ubuntu"

# 카카오 클라우드 (주석)
# MAIN_HOST="61.109.236.16"
# GPU_HOST="61.109.238.4"
# GPU_PRIVATE="10.0.83.48"

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }

deploy_redis() {
    log "Deploying Redis..."
    ssh ${SSH_USER}@${MAIN_HOST} << 'EOF'
docker stop tcurity-redis 2>/dev/null || true
docker rm tcurity-redis 2>/dev/null || true
docker run -d --name tcurity-redis --restart unless-stopped \
    -p 6379:6379 redis:7-alpine redis-server --appendonly yes
EOF
}

deploy_backend() {
    log "Deploying Backend..."
    ssh ${SSH_USER}@${MAIN_HOST} << EOF
docker pull ${REGISTRY}/${ORG}/backend:develop
docker stop tcurity-backend 2>/dev/null || true
docker rm tcurity-backend 2>/dev/null || true
docker run -d --name tcurity-backend --restart unless-stopped \
    -p 8000:8000 \
    -e AI_SERVER_URL=http://${GPU_PRIVATE}:9000 \
    -e REDIS_URL=redis://localhost:6379 \
    ${REGISTRY}/${ORG}/backend:develop
docker image prune -f
EOF
}

deploy_ai() {
    log "Deploying AI Server..."
    ssh ${SSH_USER}@${GPU_HOST} << EOF
docker pull ${REGISTRY}/${ORG}/ai:develop
docker stop tcurity-ai 2>/dev/null || true
docker rm tcurity-ai 2>/dev/null || true
docker run -d --name tcurity-ai --restart unless-stopped \
    --gpus all -p 9000:9000 \
    -v /home/ubuntu/tcurity-ai/models:/app/models:ro \
    -v /home/ubuntu/tcurity-ai/data:/app/data:ro \
    -e MLFLOW_EXPERIMENT_NAME=captcha-effnet-tracking \
    -e IMAGE_DATA_ROOT=/app/data/images \
    -e MODEL_OUTPUT_ROOT=/app/models \
    -e PHASE_B_PROBLEM_IMAGE_ROOT=/app/data/processed_images \
    ${REGISTRY}/${ORG}/ai:develop
docker image prune -f
EOF
}

deploy_sdk() {
    log "Deploying SDK..."
    ssh ${SSH_USER}@${MAIN_HOST} << EOF
docker pull ${REGISTRY}/${ORG}/sdk:dev
docker stop tcurity-sdk 2>/dev/null || true
docker rm tcurity-sdk 2>/dev/null || true
docker run -d --name tcurity-sdk --restart unless-stopped \
    -p 8081:80 ${REGISTRY}/${ORG}/sdk:dev
docker image prune -f
EOF
}

deploy_demo() {
    log "Deploying Demo..."
    ssh ${SSH_USER}@${MAIN_HOST} << EOF
docker pull ${REGISTRY}/${ORG}/demo:dev
docker stop tcurity-demo 2>/dev/null || true
docker rm tcurity-demo 2>/dev/null || true
docker run -d --name tcurity-demo --restart unless-stopped \
    -p 8080:80 ${REGISTRY}/${ORG}/demo:dev
docker image prune -f
EOF
}

case ${1:-all} in
    redis)   deploy_redis ;;
    backend) deploy_backend ;;
    ai)      deploy_ai ;;
    sdk)     deploy_sdk ;;
    demo)    deploy_demo ;;
    all)     deploy_redis; deploy_backend; deploy_ai; deploy_sdk; deploy_demo ;;
    *)       echo "Usage: $0 {all|backend|ai|sdk|demo|redis}"; exit 1 ;;
esac

echo "✅ Done!"
