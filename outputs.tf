output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.compute.private_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}
