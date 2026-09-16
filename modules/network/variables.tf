variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "pub_subnets" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "priv_subnets" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
}
