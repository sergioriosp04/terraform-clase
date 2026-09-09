variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "seminario"
}

variable "vpc_cidr" {
  default = "192.168.1.0/24"
}

variable "subnets" {
  default = {
    front-1 = {
      cidr   = "192.168.1.0/27"
      az     = "a"
      public = true
    }
    front-2 = {
      cidr   = "192.168.1.32/27"
      az     = "b"
      public = true
    }
    back-1 = {
      cidr   = "192.168.1.64/27"
      az     = "a"
      public = false
    }
    back-2 = {
      cidr   = "192.168.1.96/27"
      az     = "b"
      public = false
    }
    db-1 = {
      cidr   = "192.168.1.128/27"
      az     = "a"
      public = false
    }
    db-2 = {
      cidr   = "192.168.1.160/27"
      az     = "b"
      public = false
    }
  }
}