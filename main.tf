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
  tags = {
    Name = "SN-lab-2-${each.key}"
    Env  = "test"
  }
}

############ Internet Gateway ############
# Puerta de entrada/salida entre la VPC e internet. Se adjunta una sola vez
# por VPC y es lo que le permite a las subnets públicas tener ruta directa
# hacia afuera (0.0.0.0/0).
resource "aws_internet_gateway" "IGW-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id
  tags = {
    Name = "IGW-lab-2"
    Env  = "test"
  }
}

############ NAT Gateway ############
# El NAT Gateway permite que instancias en subnets privadas salgan a
# internet (para updates, descargar paquetes, etc) sin ser accesibles
# desde afuera. A diferencia del IGW, el NAT necesita una Elastic IP
# propia y tiene que crearse en una subnet PUBLICA (con ruta al IGW),
# aunque el tráfico que reenvía venga de las subnets privadas.
resource "aws_eip" "EIP-nat-lab-2" {
  domain = "vpc"
  tags = {
    Name = "EIP-nat-lab-2"
    Env  = "test"
  }
}

resource "aws_nat_gateway" "NAT-lab-2" {
  allocation_id = aws_eip.EIP-nat-lab-2.id
  subnet_id     = aws_subnet.SN-lab-2["front-1"].id
  connectivity_type = "public"

  tags = {
    Name = "NAT-lab-2"
    Env  = "test"
  }

  # El NAT depende de que el IGW ya exista, si no falla la creación.
  depends_on = [aws_internet_gateway.IGW-lab-2]
}

############ Route Tables ############
# Una route table define hacia dónde se manda el tráfico según su destino.
# Necesitamos dos: una pública (sale directo por el IGW) y una privada
# (sale por el NAT). Cada subnet se asocia a una u otra según su flag
# `public` en var.subnets.
resource "aws_route_table" "RT-public-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-lab-2.id
  }

  tags = {
    Name = "RT-public-lab-2"
    Env  = "test"
  }
}

resource "aws_route_table" "RT-private-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-lab-2.id
  }

  tags = {
    Name = "RT-private-lab-2"
    Env  = "test"
  }
}

resource "aws_route_table_association" "RTA-lab-2" {
  for_each = var.subnets

  subnet_id      = aws_subnet.SN-lab-2[each.key].id
  route_table_id = each.value.public ? aws_route_table.RT-public-lab-2.id : aws_route_table.RT-private-lab-2.id
}