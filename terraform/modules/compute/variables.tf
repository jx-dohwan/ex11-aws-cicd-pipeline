variable "tag_header" {
  description = "리소스 이름 태그 접두사"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록 (ALB 및 Bastion용)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록 (ASG 노드용)"
  type        = list(string)
}

variable "bastion_sg_id" {
  description = "Bastion 보안 그룹 ID"
  type        = string
}

variable "key_name" {
  description = "EC2 키페어 이름"
  type        = string
  default     = "std04-key"
}
