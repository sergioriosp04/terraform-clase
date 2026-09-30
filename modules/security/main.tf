########### Security Group ############
# Un security group es un firewall a nivel de instancia (stateful): si
# dejas entrar una conexión, la respuesta sale sola. Por ahora es
# laboratorio, así que permite TODO el tráfico de entrada y salida.
# protocol = "-1" significa todos los protocolos y todos los puertos.
# OJO: no usar esto en producción, restringir puertos y orígenes.
resource "aws_security_group" "allow_all" {
  name        = "SG-AllowAll-${terraform.workspace}"
  description = "Allow all inbound and outbound traffic (lab only)"
  vpc_id      = var.vpc_id

  ingress {
    description = "All inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-AllowAll-${terraform.workspace}"
  }
}

########### Security Group del Load Balancer ############
# SG exclusivo para el ALB: solo deja entrar HTTP (puerto 80) desde
# cualquier IP de internet. La salida queda abierta para que el ALB pueda
# reenviar el tráfico a las instancias y hacer los health checks.
resource "aws_security_group" "alb" {
  name        = "SG-ALB-${terraform.workspace}"
  description = "Allow HTTP inbound traffic to the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-ALB-${terraform.workspace}"
  }
}
