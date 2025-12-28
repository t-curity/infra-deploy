# T-curity Infrastructure & Deployment

T-curity CAPTCHA 시스템의 CI/CD 파이프라인 및 인프라 관리 저장소

## 📁 구조

```
infra-deploy/
├── docker/
│   ├── docker-compose.main.yml   # Main 서버 컨테이너 구성
│   ├── docker-compose.gpu.yml    # GPU 서버 컨테이너 구성
│   └── nginx/
│       └── default.conf          # Nginx 리버스 프록시 설정
├── docs/
│   ├── 인프라_구성도.md           # 시스템 아키텍처 문서
│   └── workflows/                # 각 레포용 CI/CD 워크플로우
├── scripts/
│   ├── deploy.sh                 # 수동 배포 스크립트
│   ├── status.sh                 # 서비스 상태 확인
│   ├── setup-main-server.sh      # Main 서버 초기 설정
│   └── setup-gpu-server.sh       # GPU 서버 초기 설정
└── .github/workflows/
    └── deploy.yml                # GitHub Actions 배포 워크플로우
```

## 🚀 서비스 구성

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Demo Site | 5173 | 티켓 예매 데모 (Vite) |
| SDK | 3000 | Captcha SDK (Vite) |
| Backend | 8000 | REST API (FastAPI) |
| AI Server | 9000 | AI 추론 서버 (GPU) |

## 🌐 URL 라우팅 (Nginx)

| URL 패턴 | 대상 서비스 |
|----------|-------------|
| `/` | Demo Site |
| `/ticket-site-demo/*` | Demo Site |
| `/api/*` | Backend API |
| `/sdk.js` | Captcha SDK |

## 🔧 서버 정보 (카카오 클라우드)

| 서버 | Public IP | Private IP |
|------|-----------|------------|
| Main | 61.109.236.16 | 10.0.3.151 |
| GPU | 61.109.238.4 | 10.0.83.48 |

## 📄 문서

- [인프라 구성도](docs/인프라_구성도.md) - 시스템 아키텍처 및 네트워크 구성
