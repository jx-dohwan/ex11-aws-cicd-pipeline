# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id, aws_route_table.cluster.id],
    [for rt in aws_route_table.private : rt.id]
  )
  tags = { Name = "${var.tag_header}s3-gw-endpoint" }
}
# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  # 변경: != "public" 대신 == "private" 으로 지정하여 1 AZ당 1개 서브넷만 선택되게 함
  subnet_ids         = [for k, v in aws_subnet.this : v.id if v.tags["Type"] == "private"]
  security_group_ids = [aws_security_group.endpoint_sg.id]
  tags               = { Name = "${var.tag_header}ecr-api-endpoint" }
}

# ECR DKR Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  # 변경: != "public" 대신 == "private" 으로 지정
  subnet_ids         = [for k, v in aws_subnet.this : v.id if v.tags["Type"] == "private"]
  security_group_ids = [aws_security_group.endpoint_sg.id]
  tags               = { Name = "${var.tag_header}ecr-dkr-endpoint" }
}
