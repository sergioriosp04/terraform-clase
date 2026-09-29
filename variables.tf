variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "seminario"
}

variable "vpc_cidr" {
  default = "192.168.1.0/24"
}

variable "pub_subnets" {
  default = ["192.168.1.0/27", "192.168.1.32/27"]
}

variable "priv_subnets" {
  default = [
    "192.168.1.64/27",
    "192.168.1.96/27",
    "192.168.1.128/27",
    "192.168.1.160/27",
  ]
}

variable "key_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}
