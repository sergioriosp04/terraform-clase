########### VPC ############
# La VPC es la red privada y aislada dentro de AWS donde viven todos tus
# recursos (subnets, instancias, etc). cidr_block define su rango total
# de IPs; todo lo que crees adentro tiene que caer dentro de ese rango.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-${terraform.workspace}"
  }
}

########### Internet Gateway ############
# Puerta de entrada/salida entre la VPC e internet. Se adjunta una sola vez
# por VPC y es lo que le permite a las subnets públicas tener ruta directa
# hacia afuera (0.0.0.0/0).
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW-${terraform.workspace}"
  }
}

########### Subnets ############
# Subnets públicas: tienen ruta directa al IGW (más abajo, en la route
# table) y son donde vive el NAT Gateway.
resource "aws_subnet" "public" {
  count             = length(var.pub_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.pub_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1b"][count.index % 2]

  tags = {
    Name = "Public-${count.index + 1}-${terraform.workspace}"
  }
}

# Subnets privadas: no tienen ruta directa a internet, salen a través del
# NAT Gateway (más abajo, en la route table privada).
resource "aws_subnet" "private" {
  count             = length(var.priv_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.priv_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1b"][count.index % 2]

  tags = {
    Name = "Private-${count.index + 1}-${terraform.workspace}"
  }
}

########### NAT Gateway ############
# El NAT Gateway permite que las instancias en subnets privadas salgan a
# internet sin ser accesibles desde afuera. Necesita una Elastic IP propia
# y se crea dentro de una subnet PUBLICA (la primera), aunque el tráfico
# que reenvía venga de las subnets privadas.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "EIP-NAT-${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "NAT-${terraform.workspace}"
  }

  # El NAT depende de que el IGW ya exista, si no falla la creación.
  depends_on = [aws_internet_gateway.igw]
}

########### Route Tables ############
# Una route table define hacia dónde se manda el tráfico según su destino.
# La pública sale directo por el IGW y la privada sale por el NAT. Cada
# subnet se asocia a la tabla que le corresponde según si es pública o
# privada.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "RT-Public-${terraform.workspace}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "RT-Private-${terraform.workspace}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

