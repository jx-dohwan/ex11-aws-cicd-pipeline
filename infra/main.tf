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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket       = "std04-terraform-module-state-bucket-20260918"
    key          = "terraform/codepipe/terraform.tfstate"
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

# Private 서브넷들만 자동 조회 (private2a, private2b, private2c)
data "aws_subnets" "target_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.tag_header}private*"]
  }
}

# ##########################################################################
# 테라폼기본 설정
# #########################################################################3
# 키페어 / ami / 보안그룹 / 서브넷id / 
variable "key_name" {
  description = "키페어 이름"
  type        = string
  default     = "std04"
}
variable "owner" {
  description = "사용자 계정 이름"
  type        = string
  default     = "std04"
}
variable "default_version" {
  description = ""
  type        = string
  default     = "latest" # 특정 버전을 지정하고자 할 경우 문자열 형태의 숫자 기재
}
# variable "environment" {
#   description = "프로젝트 역할 구분"
#   type        = string
#   default     = "ex" # deb / db / on / ex / lab
# }

locals {
  key_name            = var.key_name
  owner               = var.owner
  tag_header          = var.owner == "" ? "" : "${local.owner}-"
  vpc_id              = data.aws_vpc.vpc.id
  ami_id              = data.aws_ami.al2023.id
  security_groups_ids = data.aws_security_groups.security_groups.ids
  ec2_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

data "aws_region" "current" {}


data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${local.tag_header}vpc"]
  }
}

output "information" {
  value = {
    vpc_id             = local.vpc_id
    security_group_ids = data.aws_security_groups.security_groups.ids
  }
}


# Amazon Linux 2023 최신 AMI 조회
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# #################################################################################
# 인스턴스에 부여할 역할
# #################################################################################
resource "aws_iam_role" "node_role_asg" {
  name = "${local.tag_header}AmazonASGNodeEC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole" # 신뢰관계 허용(IAM Role을 임시로 획득하여 권한을 행사, 임시권한 허용)
    }]
  })

}

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.tag_header}AmazonCodePipelineService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.tag_header}CodePipelineServicePolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. S3 버킷(아티팩트) 읽기/쓰기 권한
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = "*"
      },
      # 2. GitHub 소스 연결(CodeStar Connection) 사용 권한
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      # 3. CodeDeploy 배포 실행 및 조회 권한
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      }
    ]
  })
}

# 정책 연결
resource "aws_iam_role_policy_attachment" "node_policies_asg" {
  for_each   = toset(local.ec2_policy_arns)
  role       = aws_iam_role.node_role_asg.name
  policy_arn = each.value
}

# 인스턴스 프로필 생성 - 인스턴스가 role가 정책보다 먼저 생겨서 발생한 문제라는데
resource "aws_iam_instance_profile" "node_profile_asg" {
  name = "${local.tag_header}ASGNodeEC2Instance-profile"
  role = aws_iam_role.node_role_asg.name
}

# ================================================================================
# CodeDeploy 역할(Role)
# --------------------------------------------------------------------------------
# 역할 생성
resource "aws_iam_role" "codedeploy_role" {
  name = "${local.tag_header}AmazonCodeDeployService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole" # IAM Role을 임시로 획득하여 권한을 행사할 수 있도록 허용
    }]
  })
}

# 관리형 정책을 역할에 연결
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"


}



# #################################################################################
# Pipeline 저장용 S3 Bucket
# #################################################################################
# byt_length에 정의된자릿수의 임의 숫자 반환
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# pipeline 구성에 필요한 배포 파일 저장소 생성
resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = {
    Name = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
  }
}


# 2. 생성된 버킷의 버전 관리 활성화 (CodePipeline 필수 속성)
resource "aws_s3_bucket_versioning" "pipeline_bucket_versioning" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. 퍼블릭 액세스 전체 차단 (보안 규정 준수)
resource "aws_s3_bucket_public_access_block" "pipeline_bucket_public_access" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. 서버 측 기본 암호화 설정 (SSE-S3 / AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_bucket_encryption" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3
    }
  }
}

# 5. 생성된 버킷 이름 출력 (GitHub Secret 갱신 시 필요)
output "pipeline_bucket_name" {
  description = "CodePipeline 아티팩트 S3 버킷 이름"
  value       = aws_s3_bucket.pipeline_bucket.id
}

# 인스턴스에 추가할 보안 그룹 # 필터를 두번쓰면 and value안에서 ,를 쓰면 or이다. 
# vpc_security_group_ids= data.aws_security_groups.security_groups.ids

data "aws_security_groups" "security_groups" {
  filter {
    name = "tag:Name"
    values = [
      "${local.tag_header}app-instance-sg",
      "${local.tag_header}bastion-sg"
    ]
  }
}

# vpc_security-group_ids =[data...id, data...id]
# 1. ALB 보안 그룹 조회
# data "aws_security_group" "external_alb_sg" {
#   filter {
#     name   = "tag:Name"
#     values = ["${local.tag_header}app-alb-sg"]
#   }
# }

# # 2. SSH (Bastion) 보안 조회
# data "aws_security_group" "bastion_sg" {
#   filter {
#     name   = "tag:Name"
#     values = ["${local.tag_header}bastion-sg"]
#   }
# }

# # 3. 앱 인스턴스 보안 그룹 조회 (Launch Template용)
# data "aws_security_group" "app_instance_sg" {
#   filter {
#     name   = "tag:Name"
#     values = ["${local.tag_header}app-instance-sg"]
#   }
# }


# ######################################################################################
# 서비스에 사용할 역할 생성
# ######################################################################################



# ######################################################################################
# Launch template & UserData
# ######################################################################################
# 템플릿 생성
resource "aws_launch_template" "asg_lt" {
  name_prefix            = "${local.tag_header}-"
  image_id               = local.ami_id # data.aws_ami.al2023.id
  instance_type          = "t3.small"
  key_name               = local.key_name
  vpc_security_group_ids = local.security_groups_ids

  # 인스턴스 프로파일 연결
  iam_instance_profile {
    name = aws_iam_instance_profile.node_profile_asg.name
  }

  # 기본 버전 지정 방법 --------------------------------------------------------------------
  update_default_version = var.default_version == "latest" ? true : false
  default_version        = var.default_version != "latest" ? tostring(var.default_version) : null

  # ---------------------------------------------------------------------------------------
  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y ruby wget docker

systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

cd /tmp
wget https://aws-codedeploy-${data.aws_region.current.region}.s3.${data.aws_region.current.region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent
EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.tag_header}asg-node-instance"
    }
  }
}

# ########################################################################
# Auto Scaling Group
# ########################################################################
resource "aws_autoscaling_group" "asg" {
  name                = "${local.tag_header}codedeploy-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = data.aws_subnets.target_subnets.ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  # ALB Target Group이 있다면 아래 속성 추가 (선택 사항)
  # target_group_arns = [data.aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "${local.tag_header}asg-node"
    propagate_at_launch = true
  }
}


# #####################################################################
# CodeDeploy Application & Deployment Group
# #####################################################################
resource "aws_codedeploy_app" "app" {
  name = "${local.tag_header}asg-codedeploy-app"
  # 배포 대상 정의: Server / Lambda / ECS
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "dg" {
  deployment_group_name = "${local.tag_header}asg-deployment-group"
  # codedeploy_app 리소스 이름
  app_name = aws_codedeploy_app.app.name
  # codedeploy 서비스에 추가해줄 역할(Role)
  service_role_arn = aws_iam_role.codedeploy_role.arn
  # 배포 대상 정의
  autoscaling_groups = [aws_autoscaling_group.asg.name]
  # 배포 전략(구성) 지정
  # "CodeDeployDefault.AllAtOnce":타겟 인스턴스 저ㄴ체에 동시에 한번에 배포하는 방식
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

# #####################################################################
# 연결 리소스 생성 및 CodePipeline 리소스 생성
# #####################################################################
# AWS - Github 간 CodeStar Connection 생성
# #####################################################################
resource "aws_codestarconnections_connection" "github" {
  name          = "${local.tag_header}github-connection"
  provider_type = "GitHub"
}

# #####################################################################
# 연결 리소스 생성 및 CodePipeline 리소스 생성
# #####################################################################
resource "aws_codepipeline" "codepipeline" {
  name     = "${local.tag_header}asg-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"                      # 액션 재공자(AWS에서 제공하는 서비스 활용 )
      provider = "CodeStarSourceConnection" # Github V2 액션과 연동 표준인 "CodeStarSourceConnection"사용
      version  = "1"
      # ZIP 소스 압축파일을 다음 스테이지로 전달할 전달용 아티팩트 이름 선언
      output_artifacts = ["source_output"]

      # GitHub 연동을 위한 속성값 정의
      configuration = {
        # gitHub와 CodeDeploy를 연결하는 연결 객체 정의
        ConnectionArn = aws_codestarconnections_connection.github.arn
        # GitHub Repository 이름
        FullRepositoryId = "jx-dohwan/ex11-aws-cicd-pipeline"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "CodeDeploy"
      # ZIP 소스 압축파일을 다음 스테이지로 전달할 전달용 아티팩트 이름 선언된 것을 받겠다는 것이다 
      input_artifacts = ["source_output"] # State 1의 output_artifacts에 정으된이름 
      version         = "1"

      configuration = {
        # GitHub와 CodeDepoy를 연결하는 연결 객체 정의
        ApplicationName = aws_codedeploy_app.app.name
        # 배포를 진행할 Codedeploy Deploymentgroup이름 
        DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}
