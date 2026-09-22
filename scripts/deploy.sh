#!/bin/bash
set -e

AWS_REGION="ap-northeast-2"
COMPOSE_DIR="/home/ec2-user/app/compose"

echo "=== 1. ECR 로그인 ==="
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGISTRY_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY_URL}

echo "=== 2. Nginx 마운트 디렉터리 준비 ==="
mkdir -p /home/ec2-user/nginx/conf.d
mkdir -p /home/ec2-user/nginx/html
mkdir -p /home/ec2-user/nginx/logs

# 압축 해제된 설정 파일들을 호스트 마운트 위치로 복사
cp /home/ec2-user/app/build/nginx/default.conf /home/ec2-user/nginx/conf.d/default.conf
cp -r /home/ec2-user/app/build/nginx/html/* /home/ec2-user/nginx/html/

echo "=== 3. Docker Compose 배포 실행 ==="
cd ${COMPOSE_DIR}

# 최신 이미지 Pull 후 백그라운드 재기동
docker compose pull
docker compose down || true
docker compose up -d

echo "=== 4. 미사용 이미지 정리 ==="
docker image prune -f

echo "=== 배포 완료 ==="