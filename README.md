# Clase 1 - Terraform

Laboratorio de Terraform en AWS (`us-east-1`) organizado en módulos:

- `modules/network`: VPC, subnets públicas y privadas, Internet Gateway, NAT Gateway y route tables.
- `modules/security`: security group que permite todo el tráfico (solo laboratorio).
- `modules/compute`: instancia EC2 con Amazon Linux, disco de 20 GB y un user data que instala Apache.

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

# 6. Ver la IP pública de la EC2
terraform output ec2_public_ip
```

## Probar la instancia

Esperar 1-2 minutos después del `apply` para que termine el user data y abrir en el navegador:

```
http://<ec2_public_ip>
```

Conectarse por SSH:

```bash
chmod 400 KP-lab-1.pem
ssh -i KP-lab-1.pem ec2-user@<ec2_public_ip>

# Si la página no carga, revisar el log del user data
sudo cat /var/log/cloud-init-output.log
```

## Destruir

El NAT Gateway y la Elastic IP generan costo por hora, así que hay que destruir todo al terminar el laboratorio:

```bash
terraform destroy -var-file=environments/dev.tfvars
```
