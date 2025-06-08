provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = "vpc-xxxxxxxx"  # <-- Replace with your actual VPC ID

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = {
    Name = "Allow HTTP and SSH"
  }
}

resource "aws_instance" "web_app" {
  ami           = "ami-0e001c9271cf7f3b9" # Amazon Linux 2 (Mumbai)
  instance_type = "t2.micro"
  key_name      = "your-key-name"        # <-- Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git httpd

              systemctl start httpd
              systemctl enable httpd

              cd /var/www/html
              git clone https://github.com/user/repo.git
              cp -r repo/* .

              curl -I http://localhost > /tmp/port80_check.txt
              shutdown -h +30
              EOF

  tags = {
    Name = "AutoDeployEC2"
  }
}

output "app_url" {
  value = "http://${aws_instance.web_app.public_ip}"
}
