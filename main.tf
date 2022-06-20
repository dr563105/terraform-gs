# 1. Create VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {Name = "tf_prod_vpc"}
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "prod_gw" {
  vpc_id = aws_vpc.prod_vpc.id
  # tags = {
  #   Name = "tf_prod_gw"
  # }
}
# 3. Create a subnet
resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.prod_vpc.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = "us-east-1a"

  tags = {Name = "tf_prod_subnet"}
}
resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.prod_vpc.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = "us-east-1a"

  tags = {Name = "tf_prod_subnet"}
}
# 4. Create a custom route table
resource "aws_route_table" "prod_rt" {
  vpc_id = aws_vpc.prod_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_gw.id
  }
}

# 5. Associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod_rt.id
}

# 6. Create security group to allow ports 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "webserver_nic" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}
# 8. Assign an elastic IP to the network interface for step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver_nic.id
  associate_with_private_ip = "10.0.0.50"
  depends_on = [aws_internet_gateway.prod_gw]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "webserver_instance" {
  ami = var.ec2_ami
  instance_type = var.aws_ec2_instance_type
  availability_zone = var.ec2_availabity_zone
  key_name = "mlops-zoomcamp"
  # cpu_core_count = 1
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.webserver_nic.id
  }
  tags = {Name = "tfwebserver"}
  user_data = <<-EOF
		          #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
            	EOF
}