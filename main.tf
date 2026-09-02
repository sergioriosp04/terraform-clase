########### VPC ############

resource "aws_vpc" "VPC-lab-2" {
  cidr_block = "${var.vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-lab-2"
    Env = "test"
  }
}