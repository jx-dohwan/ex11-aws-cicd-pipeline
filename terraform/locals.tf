# <변수명> = <모듈명.아웃풋이름>
locals {
  region      = "ap-northeast-2"
  az_names    = slice(data.aws_availability_zones.available_az.names, 0, 3)
  owner       = var.owner
  vpc_cidr    = var.vpc_cidr
  tag_header  = var.owner == "" ? "" : "${local.owner}-"
  cidr_header = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"
  subnet_map = merge([
    for idx, key in ["public", "private", "cluster"] : {
      for i, az_name in local.az_names : "${key}${split("-", az_name)[2]}" => {
        type = key
        az   = az_name
        cidr = "${local.cidr_header}.${i + (idx * 10 + 1)}.0/24"
      }
    }
  ]...)
}

output "subnet_map" {
  value = local.subnet_map
}
