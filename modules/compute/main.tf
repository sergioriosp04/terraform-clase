

########### EC2 ############
# Instancia en la primera subnet PRIVADA, sin IP pública: desde internet
# solo se llega a ella a través del ALB, que le habla por su IP privada.
# Para instalar paquetes sale a internet por el NAT Gateway.
# key_name es el NOMBRE del key pair que ya existe en AWS (no el archivo
# .pem); Terraform solo lo referencia, no lo crea.
resource "aws_instance" "web" {
  ami                         = "ami-0fef201115eefe936"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  # Script que corre UNA sola vez al primer arranque: instala Apache y
  # publica una página de prueba. Vive en user_data.sh dentro del módulo.
  # user_data_replace_on_change hace que si editas el script, Terraform
  # recree la instancia (si no, el cambio no se aplicaría nunca).
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # Disco raíz de 20 GB tipo gp3. Se borra al destruir la instancia.
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "EC2-${terraform.workspace}"
  }
}
