resource "aws_security_group" "bastion" {
  name   = "${var.tag_header}bastion-sg"
  vpc_id = aws_vpc.this.id

  # 22번 SSH 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 80번 HTTP 웹 허용 (필수 추가)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}bastion-sg" }
}
resource "aws_security_group" "endpoint_sg" {
  name   = "${var.tag_header}endpoint-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = { Name = "${var.tag_header}endpoint-sg" }
}

