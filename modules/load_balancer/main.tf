########### Application Load Balancer ############
# ALB público (internal = false) que recibe tráfico HTTP desde internet.
# AWS exige que un ALB esté en al menos 2 subnets de AZs distintas, por eso
# le pasamos las dos subnets públicas (us-east-1a y us-east-1b).
resource "aws_lb" "main" {
  name               = "ALB-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "ALB-${terraform.workspace}"
  }
}

########### Target Group ############
# Grupo de destinos a los que el ALB reparte el tráfico. target_type =
# "instance" significa que registramos instancias EC2 por su ID.
# El health check pide "/" cada 30 s; si la instancia no responde 200,
# el ALB deja de mandarle tráfico.
resource "aws_lb_target_group" "web" {
  name        = "TG-Web-${terraform.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "TG-Web-${terraform.workspace}"
  }
}

########### Listener ############
# El listener es el "oído" del ALB: escucha en el puerto 80 y todo lo que
# llega lo reenvía (forward) al target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

########### Target Group Attachment ############
# Registra la instancia EC2 en el target group, en el puerto 80 (Apache).
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = var.instance_id
  port             = 80
}
