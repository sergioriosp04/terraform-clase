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
