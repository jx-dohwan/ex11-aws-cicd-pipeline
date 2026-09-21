# ==============================================================================
# 1. Network Module
# ==============================================================================
module "network" {
  source       = "./modules/network"
  owner        = local.owner
  vpc_cidr     = local.vpc_cidr
  tag_header   = local.tag_header
  region       = local.region
  subnet_map   = local.subnet_map
  cluster_name = var.cluster_name
}

# ==============================================================================
# 2. Shared Store (S3 & EFS)
# ==============================================================================
resource "aws_s3_bucket" "state" {
  bucket = "${local.tag_header}state-bucket-2026"
}

resource "aws_s3_bucket" "website" {
  bucket = "${local.tag_header}website-bucket-2026"
}

resource "aws_s3_bucket" "log" {
  bucket = "${local.tag_header}log-bucket-2026"
}

resource "aws_efs_file_system" "main" {
  creation_token = "${local.tag_header}efs"
  tags           = { Name = "${local.tag_header}efs" }
}

# ==============================================================================
# 3. Compute Module (Bastion, ALB, ASG, CodeDeploy, CodePipeline)
# ==============================================================================
module "compute" {
  source             = "./modules/compute"
  tag_header         = local.tag_header
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  bastion_sg_id      = module.network.bastion_sg_id
}

# ==============================================================================
# 4. Root Outputs
# ==============================================================================
output "alb_dns_name" {
  description = "Application Load Balancer DNS Endpoint"
  value       = module.compute.alb_dns_name
}

output "codedeploy_app_name" {
  description = "CodeDeploy Application Name"
  value       = module.compute.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy Deployment Group Name"
  value       = module.compute.codedeploy_deployment_group_name
}

output "codestar_connection_arn" {
  description = "CodeStar GitHub Connection ARN"
  value       = module.compute.codestar_connection_arn
}
