
resource "aws_key_pair" "publickey" {
  key_name   = "srpvtkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG6oYC/SKicE+RhSs5wsctCrze7C0aPWpg7p9N78+QFUpkhLqQIJZpzvAT2E2TrcQA6maiZQBRM+lQ/7+2/VksWgFAPt1g4HAtLtBdRLPmx0i2JoDg9aytY2nGXD33PkXG3ocbqPxQQpP1u9elZmT7hyWyw9WUD02ftixKtJ2Kb099kAWdnttzShDMsNb3BOUjc/CSFHar+57/0O7+7BRFfTHiJAkSiD4w7FUFyT27igS8B/fiyLfGRzUp3uqxDhkuO5kKM0LrB9g59NU0LBAIK7ZgPUVIkHIN882979ED/K7b9cJEKHwCPUh09WeRluQcY5wPQntBp/pGmpGbxhtV rsa-key-20241214"
}

# hub vpc configuration

resource "aws_vpc" "hubvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.Hubvpc_name
  }
}
resource "aws_subnet" "hubsubnet" {
  vpc_id     = aws_vpc.hubvpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = var.hubsubnet_name
  }
}
# igw creation and route add

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hubvpc.id

  tags = {
    Name = "maingw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.hubvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.hubsubnet.id
  route_table_id = aws_route_table.rt.id
}

#sg configuration 

resource "aws_security_group" "hubsg" {
  name = "hub_sg"
  vpc_id = aws_vpc.hubvpc.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "http from VPC"
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
    Name = "allow_ssh"
  }
}
resource "aws_network_interface" "nic" {
  security_groups = [aws_security_group.hubsg.id]
  subnet_id   = aws_subnet.hubsubnet.id
  tags = {
    Name = "network_interface"
  }

}
resource "aws_instance" "instance" {
  ami                    = "ami-0f935a2ecd3a7bd5c"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.publickey.key_name
  user_data = <<-EOF
                #!/bin/bash
                sudo su -
                yum install httpd -y
                systemctl start httpd.service
                cd /var/www/html
                echo "<!DOCTYPE html>
                <html>
                <body>
                <h2>my life my rules 1 !!!</h2>
                <img src="https://www.fodors.com/wp-content/uploads/2020/03/CutestBabyAnimals__HERO_shutterstock_115739671.jpg" alt="Girl in a jacket" width="500" height="400">
                </body>
                </html>" > index.html
                # nohup busybox httpd -f -p 8080 &
                EOF
    tags = {
      Name = "WEB-demo"
    }
    
  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }
}
output "instance_ips" {
  value = aws_instance.instance.public_ip
}