# NAT IP & Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT는 특정 키 이름(public-a)에 의존하지 않고, Type 태그가 public인 첫 번째 서브넷에 배치
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = [for k, v in aws_subnet.this : v.id if v.tags["Type"] == "public"][0]
  depends_on    = [aws_internet_gateway.this]
  tags          = { Name = "${var.tag_header}natgw" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.tag_header}public-rt" }
}

# Private Route Table (각 AZ별 생성)
resource "aws_route_table" "private" {
  for_each = toset(["a", "b", "c"])
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${var.tag_header}private-rt-${each.key}" }
}

# Cluster Route Table (1개 통합)
resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${var.tag_header}cluster-rt" }
}

# Route Table Association - Public
resource "aws_route_table_association" "public" {
  for_each       = { for k, v in aws_subnet.this : k => v if v.tags["Type"] == "public" }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Route Table Association - Private
resource "aws_route_table_association" "private" {
  for_each  = { for k, v in aws_subnet.this : k => v if v.tags["Type"] == "private" }
  subnet_id = each.value.id
  # 가용영역 이름(예: ap-northeast-2a)의 마지막 한 글자('a', 'b', 'c')를 추출하여 정확하게 매핑
  route_table_id = aws_route_table.private[substr(each.value.availability_zone, -1, 1)].id
}

# Route Table Association - Cluster
resource "aws_route_table_association" "cluster" {
  for_each       = { for k, v in aws_subnet.this : k => v if v.tags["Type"] == "cluster" }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.cluster.id
}
