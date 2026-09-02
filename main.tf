########### VPC ############
# La VPC es la red privada y aislada dentro de AWS donde viven todos tus
# recursos (subnets, instancias, etc). cidr_block define su rango total
# de IPs; todo lo que crees adentro tiene que caer dentro de ese rango.
resource "aws_vpc" "VPC-lab-2" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-lab-2"
    Env  = "test"
  }
}

############ Subnets ############
# Una subnet es un pedacito (un sub-rango de IPs) de la VPC, siempre
# atado a una sola availability zone (AZ). Sirve para segmentar la red:
# separar capas (front/back/db), aislar tráfico y repartir recursos
# entre AZs para tolerancia a fallos. Acá creamos 6 subnets (una por
# cada key de var.subnets) con for_each, todas privadas.
resource "aws_subnet" "SN-lab-2" {
  for_each = var.subnets

  vpc_id            = aws_vpc.VPC-lab-2.id
  cidr_block        = each.value.cidr
  availability_zone = "${var.aws_region}${each.value.az}"
  # map_public_ip_on_launch: si es true, las instancias que se lancen acá
  # reciben IP pública automática. Por sí solo NO hace que la subnet sea
  # "pública" (eso lo define la route table hacia un Internet Gateway).
  map_public_ip_on_launch = each.value.public
  tags = {
    Name = "SN-lab-2-${each.key}"
    Env  = "test"
  }
}