# =============================================================================
# 1. VPC 생성
# =============================================================================
# resource "aws_vpc" "this" {
#   cidr_block           = local.vpc_cidr
#   instance_tenancy     = "default"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "${local.tag_header}vpc"
#   }
# }


resource "aws_vpc" "this" {



  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.tag_header}vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.tag_header}igw" }
}
