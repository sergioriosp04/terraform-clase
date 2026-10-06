# Clase 1 - Terraform

Laboratorio de Terraform en AWS (`us-east-1`) organizado en módulos:

- `modules/network`: VPC, subnets públicas y privadas, Internet Gateway, NAT Gateway y route tables.
- `modules/security`: security group de la EC2 (permite todo el tráfico, solo laboratorio) y security group del ALB (solo HTTP 80).
- `modules/compute`: instancia EC2 con Amazon Linux en una subnet **privada** (sin IP pública), disco de 20 GB y un user data que instala Apache.
- `modules/load_balancer`: Application Load Balancer en las subnets públicas, target group, listener HTTP 80 y registro de la EC2 en el target group.

Flujo del tráfico: `Internet → ALB (subnets públicas) → IP privada de la EC2:80 → Apache`. La EC2 sale a internet (para instalar paquetes) por el NAT Gateway.

El estado se guarda en el bucket S3 `itm-seminario-lab-2` (ver `providers.tf`).

## Requisitos

- Terraform instalado.
- AWS CLI con el perfil `seminario` configurado y credenciales válidas.
- Un key pair creado en EC2 (región `us-east-1`).

Verificar credenciales:

```bash
aws sts get-caller-identity --profile seminario
```

## Variables

La carpeta `environments/` está en el `.gitignore`, así que hay que crear el archivo `environments/dev.tfvars`:

```hcl
vpc_cidr = "192.168.1.0/24"

pub_subnets = [
  "192.168.1.0/27",
  "192.168.1.32/27",
]

priv_subnets = [
  "192.168.1.64/27",
  "192.168.1.96/27",
  "192.168.1.128/27",
  "192.168.1.160/27",
]

key_name = "KP-lab-1"
```

## Comandos

```bash
# 1. Inicializar (descarga providers, configura el backend S3 y registra los módulos).
#    Volver a correrlo cada vez que se agregue un módulo nuevo.
terraform init

# 2. Seleccionar el workspace (crearlo la primera vez)
terraform workspace new dev      # solo la primera vez
terraform workspace select dev

# 3. Formatear y validar el código
terraform fmt -recursive
terraform validate

# 4. Ver qué se va a crear
terraform plan -var-file=environments/dev.tfvars

# 5. Crear la infraestructura
terraform apply -var-file=environments/dev.tfvars

# 6. Ver el DNS del load balancer y la IP privada de la EC2
terraform output alb_dns_name
terraform output ec2_private_ip
```

## Probar la instancia

Esperar 2-3 minutos después del `apply` (el ALB tiene que quedar activo y la EC2 pasar el health check) y abrir en el navegador, **con `http://`** (el ALB no escucha HTTPS):

```
http://<alb_dns_name>
```

La EC2 no tiene IP pública, así que no se puede entrar por SSH directo desde internet. Para revisar el log del user data sin conectarse: consola de EC2 → la instancia → *Actions* → *Monitor and troubleshoot* → *Get system log*.

Para ver a qué instancia está atado el ALB: consola de EC2 → *Target Groups* → `TG-Web-dev` → pestaña *Targets* (debe decir `healthy`).

## Destruir

El NAT Gateway, la Elastic IP y el load balancer generan costo por hora, así que hay que destruir todo al terminar el laboratorio:

```bash
terraform destroy -var-file=environments/dev.tfvars
```
