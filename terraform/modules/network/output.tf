# # 전체 서브넷 리소스 맵
# output "subnets" {
#   description = "생성된 전체 서브넷 객체 맵"
#   value       = aws_subnet.this
# }

# # 프라이빗 서브넷 ID 리스트 (RDS, Lambda용)
# output "private_subnet_ids" {
#   description = "프라이빗 서브넷 ID 목록"
#   value = [
#     for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "private"
#   ]
# }

# # 퍼블릭 서브넷 ID 리스트 (ALB, NAT GW용)
# output "public_subnet_ids" {
#   description = "퍼블릭 서브넷 ID 목록"
#   value = [
#     for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "public"
#   ]
# }

# output "vpc_id" {
#   value = aws_vpc.this.id
# }


# output "public_subnets" {
#   value = [for k, v in aws_subnet.this : v.id if v.tags["Type"] == "public"]
# }
# output "bastion_sg_id" {
#   value = aws_security_group.bastion.id
# }
# modules/network/output.tf 최종 내용

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.this.id
}

output "subnets" {
  description = "전체 서브넷 리소스 맵"
  value       = aws_subnet.this
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value = [
    for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "public"
  ]
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value = [
    for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "private"
  ]
}

output "cluster_subnet_ids" {
  description = "EKS 클러스터 및 노드그룹 서브넷 ID 목록"
  value = [
    for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "cluster"
  ]
}

output "public_subnets" {
  description = "기존 호환용 퍼블릭 서브넷 ID 목록"
  value       = [for k, v in aws_subnet.this : v.id if var.subnet_map[k].type == "public"]
}

output "bastion_sg_id" {
  description = "Bastion 보안 그룹 ID"
  value       = aws_security_group.bastion.id
}
