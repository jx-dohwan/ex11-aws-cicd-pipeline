# network/subnet.tf

resource "aws_subnet" "this" {
  for_each = var.subnet_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = merge(
    {
      Name = "${var.tag_header}${each.key}-subnet"
      Type = each.value.type
    },
    # Public 서브넷 EKS/ELB 태그
    each.value.type == "public" ? {
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    } : {},
    # Cluster 서브넷 EKS/Internal ELB 태그
    each.value.type == "cluster" ? {
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    } : {}
  )
}
