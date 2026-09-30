variable "vpc_id" {
  description = "ID of the VPC where the target group is created"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the public subnets for the load balancer (at least 2 AZs)"
  type        = list(string)
}

variable "sg_id" {
  description = "ID of the security group attached to the load balancer"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance registered in the target group"
  type        = string
}
