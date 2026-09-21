# 1. 테라폼 실행환경 설정 블록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # 프로바이더라이브러리 다운로드 경로
      version = "~> 6.0"        # 사용할 버전 정의
    }
  }
}
