variable "subnet_id" {
  description = "ID of the subnet where the instance is created"
  type        = string
}

variable "sg_id" {
  description = "ID of the security group attached to the instance"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}
