provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0a7d80731ae1b2435"
  instance_type = "t2.micro"
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.upload_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data = file("startup.sh")
  tags = { Name = "AppEC2" }
}
