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

############ Network ACLs ############
# Las NACLs filtran tráfico a nivel de subnet y son stateless (a diferencia
# de los Security Groups, hay que permitir explícitamente ida y vuelta).
# Acá van por tier (front/back/db), armando una topología en estrella
# donde back es el punto central: front <-> back <-> db, y front <-> db
# queda bloqueado (no hay ninguna regla que lo permita).
#
# Cada aws_network_acl se crea vacía (sin ingress/egress inline) y las
# reglas se agregan una por una con aws_network_acl_rule, para que quede
# claro qué hace cada regla individualmente.

resource "aws_network_acl" "NACL-front-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id
  subnet_ids = [
    aws_subnet.SN-lab-2["front-1"].id,
    aws_subnet.SN-lab-2["front-2"].id,
  ]

  tags = {
    Name = "NACL-front-lab-2"
    Env  = "test"
  }
}

resource "aws_network_acl" "NACL-back-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id
  subnet_ids = [
    aws_subnet.SN-lab-2["back-1"].id,
    aws_subnet.SN-lab-2["back-2"].id,
  ]

  tags = {
    Name = "NACL-back-lab-2"
    Env  = "test"
  }
}

resource "aws_network_acl" "NACL-db-lab-2" {
  vpc_id = aws_vpc.VPC-lab-2.id
  subnet_ids = [
    aws_subnet.SN-lab-2["db-1"].id,
    aws_subnet.SN-lab-2["db-2"].id,
  ]

  tags = {
    Name = "NACL-db-lab-2"
    Env  = "test"
  }
}

############ Network ACL Rules ############
# --- NACL-front: solo permite entrada/salida hacia las subnets de back ---
resource "aws_network_acl_rule" "NACLR-front-in-back-1" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-front-in-back-2" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-2"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-front-out-back-1" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-front-out-back-2" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-2"].cidr
  from_port      = 0
  to_port        = 0
}

# Front también queda expuesto a internet: entra cualquiera (All Traffic
# desde 0.0.0.0/0) y, como la NACL es stateless, hace falta la regla de
# salida aparte para que la respuesta pueda volver por los puertos
# efímeros del cliente (Custom TCP 1025-65535).
resource "aws_network_acl_rule" "NACLR-front-in-internet" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 300
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-front-out-internet-ephemeral" {
  network_acl_id = aws_network_acl.NACL-front-lab-2.id
  rule_number    = 300
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1025
  to_port        = 65535
}

# --- NACL-back: permite entrada/salida hacia front y hacia db ---
resource "aws_network_acl_rule" "NACLR-back-in-front-1" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["front-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-in-front-2" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["front-2"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-in-db-1" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 300
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["db-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-in-db-2" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 400
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["db-2"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-out-front-1" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["front-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-out-front-2" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["front-2"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-out-db-1" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 300
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["db-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-back-out-db-2" {
  network_acl_id = aws_network_acl.NACL-back-lab-2.id
  rule_number    = 400
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["db-2"].cidr
  from_port      = 0
  to_port        = 0
}

# --- NACL-db: solo permite entrada/salida hacia las subnets de back ---
resource "aws_network_acl_rule" "NACLR-db-in-back-1" {
  network_acl_id = aws_network_acl.NACL-db-lab-2.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-db-in-back-2" {
  network_acl_id = aws_network_acl.NACL-db-lab-2.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-2"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-db-out-back-1" {
  network_acl_id = aws_network_acl.NACL-db-lab-2.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-1"].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "NACLR-db-out-back-2" {
  network_acl_id = aws_network_acl.NACL-db-lab-2.id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.subnets["back-2"].cidr
  from_port      = 0
  to_port        = 0
}