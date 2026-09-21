# locals {
#   tag_header = var.tag_header
# }

# data "aws_region" "current" {}

# # ======================================================================
# # 1. IAM Roles & Instance Profile
# # ======================================================================

# # (1) EC2 Instance Role (ASG Nodes)
# resource "aws_iam_role" "asg_node_role" {
#   name = "${local.tag_header}AmazonASGNodeEC2-Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#       Action    = "sts:AssumeRole" # 신뢰관계 허용(IAM Role을 임시로 획득하여 권한을 행사, 임시권한 허용)
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecr_read" {
#   role       = aws_iam_role.asg_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_role_policy_attachment" "s3_read" {
#   role       = aws_iam_role.asg_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
# }

# resource "aws_iam_role_policy_attachment" "ssm_core" {
#   role       = aws_iam_role.asg_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "asg_node_profile" {
#   name = "${local.tag_header}ASGNodeEC2Instance-profile"
#   role = aws_iam_role.asg_node_role.name
# }

# # (2) CodeDeploy Service Role
# resource "aws_iam_role" "codedeploy_role" {
#   name = "${local.tag_header}AmazonCodeDeployService-Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "codedeploy.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
#   role       = aws_iam_role.codedeploy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
# }

# # ======================================================================
# # 2. Security Groups & ALB
# # ======================================================================

# resource "aws_security_group" "alb_sg" {
#   name   = "${local.tag_header}app-alb-sg"
#   vpc_id = var.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "${local.tag_header}app-alb-sg" }
# }

# resource "aws_security_group" "app_sg" {
#   name   = "${local.tag_header}app-instance-sg"
#   vpc_id = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "${local.tag_header}app-instance-sg" }
# }

# # Bastion Host
# data "aws_ami" "ubuntu_24_04" {
#   most_recent = true
#   owners      = ["099720109477"]

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
#   }
# }

# resource "aws_instance" "bastion" {
#   ami                         = data.aws_ami.ubuntu_24_04.id
#   instance_type               = "t3.micro"
#   key_name                    = var.key_name
#   subnet_id                   = var.public_subnet_ids[0]
#   vpc_security_group_ids      = [var.bastion_sg_id]
#   user_data_replace_on_change = true

#   root_block_device {
#     volume_size = 8
#   }

#   user_data = <<-EOF
# #!/bin/bash
# apt-get update -y
# apt-get install -y docker.io curl unzip
# systemctl enable --now docker
# usermod -aG docker ubuntu
# EOF

#   tags = { Name = "${local.tag_header}bastion-ec2" }
# }

# # Application Load Balancer
# resource "aws_lb" "app_alb" {
#   name               = "${local.tag_header}app-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = var.public_subnet_ids

#   tags = { Name = "${local.tag_header}app-alb" }
# }

# resource "aws_lb_target_group" "app_tg" {
#   name        = "${local.tag_header}app-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"

#   health_check {
#     enabled             = true
#     path                = "/"
#     port                = "80"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 15
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#   }

#   tags = { Name = "${local.tag_header}app-tg" }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_tg.arn
#   }
# }

# # ======================================================================
# # 3. Launch Template & UserData
# # ======================================================================

# data "aws_ami" "al2023" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.*-x86_64"]
#   }
# }

# resource "aws_launch_template" "asg_lt" {
#   name_prefix   = "${local.tag_header}asg-launch-template-"
#   image_id      = data.aws_ami.al2023.id
#   instance_type = "t3.micro"
#   key_name      = var.key_name

#   # 하드코딩된 SG 대신 모듈 내부 생성 SG 연동
#   vpc_security_group_ids = [aws_security_group.app_sg.id]

#   update_default_version = var.default_version == "latest" ? true : false
#   default_version        = var.default_version != "latest" ? tostring(var.default_version) : null


#   iam_instance_profile {
#     name = aws_iam_instance_profile.asg_node_profile.name
#   }

#   user_data = base64encode(<<-EOF
# #!/bin/bash
# dnf update -y
# dnf install -y ruby wget docker

# systemctl start docker
# systemctl enable docker
# usermod -aG docker ec2-user

# cd /tmp
# wget https://aws-codedeploy-${data.aws_region.current.name}.s3.${data.aws_region.current.name}.amazonaws.com/latest/install
# chmod +x ./install
# ./install auto

# systemctl start codedeploy-agent
# systemctl enable codedeploy-agent
# EOF
#   )


#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "${local.tag_header}asg-node-instance"
#     }
#   }
# }

# # ======================================================================
# # 4. Auto Scaling Group
# # ======================================================================

# resource "aws_autoscaling_group" "asg" {
#   name                = "${local.tag_header}codedeploy-asg"
#   min_size            = 1
#   max_size            = 3
#   desired_capacity    = 2
#   vpc_zone_identifier = var.private_subnet_ids

#   launch_template {
#     id      = aws_launch_template.asg_lt.id
#     version = "$Latest"
#   }

#   target_group_arns = [aws_lb_target_group.app_tg.arn]
# }

# # ======================================================================
# # 5. CodeDeploy Application & Deployment Group
# # ======================================================================

# resource "aws_codedeploy_app" "app" {
#   compute_platform = "Server"
#   name             = "${local.tag_header}asg-codedeploy-app"
# }

# resource "aws_codedeploy_deployment_group" "dg" {
#   app_name               = aws_codedeploy_app.app.name
#   deployment_group_name  = "${local.tag_header}asg-deployment-group"
#   service_role_arn       = aws_iam_role.codedeploy_role.arn
#   autoscaling_groups     = [aws_autoscaling_group.asg.name]
#   deployment_config_name = "CodeDeployDefault.AllAtOnce"
# }

# # ======================================================================
# # 6. CodePipeline 서비스 IAM Role
# # ======================================================================

# resource "aws_iam_role" "codepipeline_role" {
#   name = "${local.tag_header}AmazonCodePipelineService-Role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "codepipeline.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy" "codepipeline_policy" {
#   name = "${local.tag_header}CodePipelineServicePolicy"
#   role = aws_iam_role.codepipeline_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObjectAcl", "s3:PutObject"]
#         Resource = "*"
#       },
#       {
#         Effect   = "Allow"
#         Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "codedeploy:CreateDeployment",
#           "codedeploy:GetApplication",
#           "codedeploy:GetApplicationRevision",
#           "codedeploy:GetDeployment",
#           "codedeploy:GetDeploymentConfig",
#           "codedeploy:RegisterApplicationRevision"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # ======================================================================
# # 7. S3 Bucket & CodeStar GitHub Connection & CodePipeline
# # ======================================================================

# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }

# resource "aws_s3_bucket" "pipeline_bucket" {
#   bucket        = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
#   force_destroy = true

#   tags = {
#     Name = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
#   }
# }

# # 2. 생성된 버킷의 버전 관리 활성화 (CodePipeline 필수 속성)
# resource "aws_s3_bucket_versioning" "pipeline_bucket_versioning" {
#   bucket = aws_s3_bucket.pipeline_bucket.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # 3. 퍼블릭 액세스 전체 차단 (보안 규정 준수)
# resource "aws_s3_bucket_public_access_block" "pipeline_bucket_public_access" {
#   bucket = aws_s3_bucket.pipeline_bucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # 4. 서버 측 기본 암호화 설정 (SSE-S3 / AES256)
# resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_bucket_encryption" {
#   bucket = aws_s3_bucket.pipeline_bucket.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_codestarconnections_connection" "github" {
#   name          = "${local.tag_header}github-connection"
#   provider_type = "GitHub"
# }

# resource "aws_codepipeline" "codepipeline" {
#   name     = "${local.tag_header}asg-cicd-pipeline"
#   role_arn = aws_iam_role.codepipeline_role.arn

#   artifact_store {
#     location = aws_s3_bucket.pipeline_bucket.bucket
#     type     = "S3"
#   }

#   stage {
#     name = "Source"

#     action {
#       name             = "Source"
#       category         = "Source"
#       owner            = "AWS"
#       provider         = "CodeStarSourceConnection"
#       version          = "1"
#       output_artifacts = ["source_output"]

#       configuration = {
#         ConnectionArn    = aws_codestarconnections_connection.github.arn
#         FullRepositoryId = "jx-dohwan/ex11-aws-cicd-pipeline"
#         BranchName       = "main"
#       }
#     }
#   }

#   stage {
#     name = "Deploy"

#     action {
#       name            = "Deploy"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "CodeDeploy"
#       input_artifacts = ["source_output"]
#       version         = "1"

#       configuration = {
#         ApplicationName     = aws_codedeploy_app.app.name
#         DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
#       }
#     }
#   }
# }
locals {
  tag_header = var.tag_header
}

data "aws_region" "current" {}

# ======================================================================
# 1. IAM Roles & Instance Profile
# ======================================================================

# (1) EC2 Instance Role (ASG Nodes)
resource "aws_iam_role" "asg_node_role" {
  name = "${local.tag_header}AmazonASGNodeEC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.asg_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "asg_node_profile" {
  name = "${local.tag_header}ASGNodeEC2Instance-profile"
  role = aws_iam_role.asg_node_role.name
}

# (2) CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_role" {
  name = "${local.tag_header}AmazonCodeDeployService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ======================================================================
# 2. Security Groups & ALB
# ======================================================================

resource "aws_security_group" "alb_sg" {
  name   = "${local.tag_header}app-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.tag_header}app-alb-sg" }
}

resource "aws_security_group" "app_sg" {
  name   = "${local.tag_header}app-instance-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.tag_header}app-instance-sg" }
}

# Bastion Host
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu_24_04.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_sg_id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 8
  }

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io curl unzip
systemctl enable --now docker
usermod -aG docker ubuntu
EOF

  tags = { Name = "${local.tag_header}bastion-ec2" }
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${local.tag_header}app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${local.tag_header}app-alb" }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${local.tag_header}app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "${local.tag_header}app-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ======================================================================
# 3. Launch Template & UserData
# ======================================================================

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "asg_lt" {
  name_prefix   = "${local.tag_header}asg-launch-template-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  update_default_version = var.default_version == "latest" ? true : false
  default_version        = var.default_version != "latest" ? tostring(var.default_version) : null

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_node_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y ruby wget docker

systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

cd /tmp
wget https://aws-codedeploy-${data.aws_region.current.name}.s3.${data.aws_region.current.name}.amazonaws.com/latest/install
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

# ======================================================================
# 4. Auto Scaling Group
# ======================================================================

resource "aws_autoscaling_group" "asg" {
  name                = "${local.tag_header}codedeploy-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]
}

# ======================================================================
# 5. CodeDeploy Application & Deployment Group
# ======================================================================

resource "aws_codedeploy_app" "app" {
  compute_platform = "Server"
  name             = "${local.tag_header}asg-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "dg" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${local.tag_header}asg-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  autoscaling_groups     = [aws_autoscaling_group.asg.name]
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

# ======================================================================
# 6. CodePipeline 서비스 IAM Role
# ======================================================================

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
      # 1. S3 버킷 권한
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
      # 2. [수정됨] CodeStar GitHub 연결 사용 권한
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      },
      # 3. CodeBuild 실행 권한
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      # 4. CodeDeploy 배포 실행 권한
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

# ======================================================================
# 7. S3 Bucket & CodeStar GitHub Connection & CodePipeline
# ======================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${local.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_s3_bucket_versioning" "pipeline_bucket_versioning" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_bucket_public_access" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_bucket_encryption" {
  bucket = aws_s3_bucket.pipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 👉 이 리소스가 배포되어야 콘솔 목록에 나타납니다.
resource "aws_codestarconnections_connection" "github" {
  name          = "${local.tag_header}github-connection"
  provider_type = "GitHub"
}

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
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "jx-dohwan/ex11-aws-cicd-pipeline"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}
