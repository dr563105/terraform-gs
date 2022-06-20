variable "subnet_cidr" {
  type = list
  default = ["10.0.0.0/24","10.0.2.0/24"]
}
variable "aws_ec2_instance_type" {
  type = string
  default = "t2.micro"
}
variable "ec2_ami" {
  type = string
  default = "ami-08d4ac5b634553e16"
}
variable "ec2_availabity_zone" {
  type = string
  default = "us-east-1a"
}