data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.public_web.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.mysql.address
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = random_password.db_password.result
  })

  depends_on = [aws_db_instance.mysql]

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
