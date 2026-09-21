variable "owner" {
  description = "사용자 계정명"
  type        = string
  default     = ""
}

variable "az_names" {
  description = "가용영역 이름"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  type        = string
  default     = "std04-eks-cluster"
  description = "EKS 클러스터 이름 (서브넷 태그 연동)"
}

variable "office_cidr" {
  type        = string
  default     = "0.0.0.0/0" # 실무 환경 시 관리자 공인 IP/32로 대체
  description = "관리자 접속 허용 CIDR"
}
variable "region" {
  type        = string
  description = "ap-northeast-2"
}

