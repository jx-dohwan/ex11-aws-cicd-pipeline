# ==============================================================================
# 1. 테라폼 실행 환경 및 필수 프로바이더 설정
# ==============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  backend "s3" {
    bucket       = "std04-terraform-module-state-bucket-20260918"
    key          = "terraform/module/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }
}

# ==============================================================================
# 2. AWS Provider
# ==============================================================================
provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Owner = "std04"
      Class = "bipa17"
    }
  }
}

provider "aws" {
  alias  = "dokyo"
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Owner = "std04"
      Class = "bipa17"
    }
  }
}
