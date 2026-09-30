output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.compute.public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}
