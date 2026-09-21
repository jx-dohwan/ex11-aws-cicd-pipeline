variable "owner" {
  description = "사용자 계정명"
  type        = string
  default     = ""
}
variable "vpc_cidr" {
  type = string
}
variable "tag_header" {
  description = "태크 헤더값"
  type        = string
  default     = ""
}
variable "az_names" {
  description = "가용영역 이름"
  type        = list(string)
  default     = []
}
variable "subnet_map" {
  description = "루트 locals에서 계산된 서브넷 맵 정보"
  type = map(object({
    type = string
    az   = string
    cidr = string
  }))
}

variable "region" {}
variable "cluster_name" {}
