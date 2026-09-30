output "sg_id" {
  description = "ID of the allow-all security group"
  value       = aws_security_group.allow_all.id
}

output "alb_sg_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.alb.id
}
