terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Owner = "std04"
      Class = "bipa17"
    }
  }
}

# 1. 상태 파일 저장을 위한 S3 버킷
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "std04-terraform-module-state-bucket-20260918"
  force_destroy = true
}

# 2. S3 버전 관리 활성화 (실수로 state 삭제/덮어쓰기 방지)
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. 기본 암호화 적용 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. 퍼블릭 액세스 완전 차단 (민감 데이터 유출 방지)
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
