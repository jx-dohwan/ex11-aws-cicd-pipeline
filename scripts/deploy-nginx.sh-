#!/bin/bash
set -e

AWS_REGION="ap-northeast-2"
ECR_REPOSITORY="std04/nginx"
CONTAINER_NAME="nginx-app"

# 1. AWS 계정 ID 조회 및 전체 이미지 URI 구성
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGISTRY_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_URI="${REGISTRY_URL}/${ECR_REPOSITORY}:latest"

echo "=== 배포 대상 이미지: ${IMAGE_URI} ==="

# 2. ECR 로그인
echo "=== ECR 로그인 시도 ==="
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY_URL}

# 3. Docker 이미지 Pull
echo "=== 최신 이미지 Pull ==="
docker pull ${IMAGE_URI}

# 4. 기존 컨테이너 정리 및 신규 배포
echo "=== 기존 컨테이너 정리 ==="
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo "=== 신규 컨테이너 가동 ==="
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 80:80 \
  --restart always \
  ${IMAGE_URI}

# 5. 미사용 댕글링(Dangling) 이미지 정리
echo "=== 미사용 이미지 정리 ==="
docker image prune -f

echo "=== 배포 완료 ==="