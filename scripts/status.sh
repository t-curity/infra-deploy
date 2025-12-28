#!/bin/bash
# ============================================================
# T-curity Status Check
# ============================================================
set -e

# AWS 테스트
MAIN_HOST="43.201.104.130"
GPU_HOST="43.203.216.206"
SSH_USER="ubuntu"

# 카카오 (주석)
# MAIN_HOST="61.109.236.16"
# GPU_HOST="61.109.238.4"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "T-curity Service Status"
echo "=========================================="

echo -e "\n${YELLOW}[Main Server: $MAIN_HOST]${NC}"
ssh -o ConnectTimeout=5 ${SSH_USER}@${MAIN_HOST} \
    "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep tcurity" 2>/dev/null || echo "Connection failed"

echo -e "\n${YELLOW}[GPU Server: $GPU_HOST]${NC}"
ssh -o ConnectTimeout=5 ${SSH_USER}@${GPU_HOST} \
    "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep tcurity; echo ''; nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader" 2>/dev/null || echo "Connection failed"

echo -e "\n${YELLOW}[Health Checks]${NC}"
for svc in "Backend:${MAIN_HOST}:8000/health" "AI:${GPU_HOST}:9000/health" "Demo:${MAIN_HOST}:5173" "SDK:${MAIN_HOST}:3000"; do
    name="${svc%%:*}"
    url="http://${svc#*:}"
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "$name: ${GREEN}✓${NC}"
    else
        echo -e "$name: ${RED}✗${NC}"
    fi
done

echo "=========================================="
