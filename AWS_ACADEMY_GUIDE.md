# ⚠️ Configuración Especial para AWS Academy

## 🔴 Limitaciones Críticas de AWS Academy

AWS Academy tiene restricciones significativas que afectan el despliegue:

### 1. **Limitaciones de Recursos**
- ❌ **NAT Gateway**: NO disponible o con cuota muy baja
- ⚠️ **Load Balancer**: Cuota limitada (máximo 1-2)
- ⚠️ **RDS Multi-AZ**: No recomendado (requiere 2 instancias)
- ⚠️ **ECS Fargate**: Cuota limitada de vCPU
- ⚠️ **EC2**: Instancias t3 muy limitadas
- ⚠️ **ECR**: Posible restricción de permisos

### 2. **Limitaciones de Servicios**
- ❌ CloudFormation: Posible restricción
- ❌ VPC Endpoints: No disponibles
- ⚠️ IAM Roles: Pueden tener restricciones de confianza
- ⚠️ Secrets Manager: Posible restricción

### 3. **Limitaciones de Tiempo**
- ⏱️ Las credenciales expiran (~4 horas típicamente)
- ⏱️ Acceso a AWS solo durante las sesiones de laboratorio
- 📌 El estado de Terraform se pierde entre sesiones

---

## ✅ Soluciones para AWS Academy

### Opción 1: Terraform Simplificado (Recomendado)
Sin NAT Gateway, sin Multi-AZ, con ECS más pequeño.

### Opción 2: Despliegue Manual
Crear recursos manualmente en AWS Console durante la sesión.

### Opción 3: Documentación para AWS Comercial
Preparar Terraform para cuando uses una cuenta AWS de verdad.

---

## 🔧 Configuración Ajustada para AWS Academy

### terraform/terraform.academy.tfvars
```hcl
# AWS Academy Configuration - Optimizada para limitaciones
aws_region = "us-east-1"
project_name = "innovatech"
environment = "academy"  # Distinto a "production"

# SIMPLIFICADO para AWS Academy
vpc_cidr = "10.0.0.0/16"

# Database - Instancia más pequeña
db_instance_class = "db.t2.micro"  # t2 es más accesible que t3
db_allocated_storage = 20
db_engine_version = "8.0.35"

# ECS - Reducido
ecs_task_cpu = "256"
ecs_task_memory = "512"
ecs_desired_count = 1  # Solo 1 tarea (no 2)

# Scaling - Desactivado en Academy
enable_autoscaling = false  # Evitar complicaciones

# Imágenes (se actualizarán por CI/CD)
ventas_api_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest"
despacho_api_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest"
frontend_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest"

# Database
db_username = "innovatech"
db_password = "Academy123!SecurePass"  # Cambiar antes de usar

# Sin Multi-AZ en Academy
multi_az_enabled = false
backup_retention_days = 7  # Máximo permitido

common_tags = {
  Project     = "Innovatech"
  Environment = "Academy"
  ManagedBy   = "Terraform"
}
```

---

## ⚠️ Cambios Requeridos en main.tf

Para AWS Academy, necesitas modificar `terraform/main.tf`:

### 1. Desactivar NAT Gateway
```hcl
# Comentar o eliminar NAT Gateway
# resource "aws_nat_gateway" "nat" { ... }
```

### 2. Usar rutas directas
```hcl
# Private route table usa Internet Gateway en su lugar
route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id  # En lugar de NAT
}
```

### 3. Multi-AZ opcional
```hcl
multi_az = var.multi_az_enabled  # false en Academy
```

### 4. Instancia RDS más pequeña
```hcl
instance_class = var.db_instance_class  # db.t2.micro
```

---

## 🎯 Pasos para AWS Academy

### 1. **Verificar Créditos y Acceso**
```bash
# Confirmar que tienes acceso activo
aws sts get-caller-identity
aws ec2 describe-instances --region us-east-1
```

### 2. **Crear archivo de configuración Academy**
```bash
cp terraform/terraform.academy.tfvars terraform/terraform.tfvars
```

### 3. **Revisar Limitaciones**
```bash
# Ver cuotas de servicio
aws service-quotas list-service-quotas --service-code ec2 --query 'ServiceQuotas[*].{Name:ServiceName,Value:Value}' --output table
```

### 4. **Inicializar Terraform (sin backend remoto)**
```bash
cd terraform
terraform init  # Sin backend-config (usa local)
```

### 5. **Plan y Apply**
```bash
terraform plan -var-file="terraform.academy.tfvars"
terraform apply -var-file="terraform.academy.tfvars"
```

---

## 📊 Arquitectura Simplificada para AWS Academy

```
┌─────────────────────────────────────────────┐
│  AWS Academy (Credenciales temporales)     │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Internet (0.0.0.0/0)              │   │
│  └────────────────┬────────────────────┘   │
│                   │                        │
│  ┌────────────────▼─────────────────────┐  │
│  │  ALB (Port 80)                       │  │
│  └────────────────┬─────────────────────┘  │
│                   │                        │
│  ┌────────────────▼─────────────────────┐  │
│  │  VPC (10.0.0.0/16)                  │  │
│  │                                      │  │
│  │  ┌────────────────────────────────┐ │  │
│  │  │ Public Subnet                  │ │  │
│  │  │ ECS Tasks (1 de cada)          │ │  │
│  │  │ RDS MySQL (db.t2.micro)        │ │  │
│  │  └────────────────────────────────┘ │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘

❌ Sin NAT Gateway
❌ Sin Multi-AZ
⚠️  Deseo count = 1
✅ Funcional para testing
```

---

## ⏱️ Gestión del Tiempo en AWS Academy

AWS Academy tiene límites de tiempo. Aquí está el plan:

### Durante la Sesión (4-8 horas típicas)

1. **Setup inicial** (10 min)
   - Run setup-cicd-aws.sh (o manual en console)
   - Configure GitHub Secrets

2. **Terraform deploy** (10-15 min)
   - terraform init
   - terraform apply

3. **Testing** (Resto del tiempo)
   - Pushear a develop (CI)
   - Crear PR a main (CD plan)
   - Merge (CD apply)

4. **Documentar resultados**
   - URLs de endpoints
   - Configuración final
   - Problemas encontrados

### Después de la Sesión

- Exportar Terraform state si es posible
- Documentar todo (no se borra)
- Preparar para siguiente sesión
- Usar local backend (no S3 remote)

---

## 🚀 Comando Quick Start para AWS Academy

```bash
# 1. Copiar configuración Academy
cp terraform/terraform.academy.tfvars terraform/terraform.tfvars

# 2. Inicializar (local backend, sin S3)
cd terraform
terraform init

# 3. Plan
terraform plan -var-file="terraform.academy.tfvars" -out=tfplan

# 4. Apply (si todo se ve bien)
terraform apply tfplan

# 5. Obtener outputs
terraform output
```

---

## 📌 Importante: Estado Local vs Remoto

### En AWS Academy usa Local Backend:
```bash
# NO necesitas S3 ni DynamoDB
terraform init  # Esto crea terraform.tfstate localmente
```

### Guarda el archivo localmente:
```bash
# terraform.tfstate se crea en el directorio actual
# NO lo subas a git (ya está en .gitignore)
```

### Para siguiente sesión:
```bash
# Si recuperas el terraform.tfstate anterior
terraform init  # Detectará el state existente
```

---

## ⚠️ GitHub Actions en AWS Academy

**PROBLEMA**: Las credenciales de AWS Academy expiran rápido.

**SOLUCIÓN**: 

### Opción A: CI sin AWS
```yaml
# ci-develop.yml funciona normalmente
# No requiere AWS credentials
```

### Opción B: CD Desactivado
```yaml
# cd-deploy.yml requiere AWS credentials
# Puede fallar si credenciales expiraron
```

### Opción C: Manual CD
- Hacer los deploys manualmente durante la sesión
- No usar CD workflow en GitHub Actions

---

## ✅ Checklist para AWS Academy

- [ ] Acceso activo a AWS Academy confirmado
- [ ] Créditos suficientes verificados
- [ ] Región correcta (us-east-1)
- [ ] IAM permisos confirmados
- [ ] terraform.academy.tfvars creado
- [ ] Backend local (no S3)
- [ ] terraform init sin backend-config
- [ ] Limites de recursos revisados
- [ ] ALB, NAT Gateway evaluados
- [ ] Multi-AZ desactivado
- [ ] Desired count = 1
- [ ] terraform.tfstate en .gitignore

---

## 📞 Soporte para AWS Academy

Si encuentras problemas:

1. **Credenciales expiradas**: Las expiran después de N horas
   - Vuelve a autenticar: `aws configure`

2. **Cuota excedida**: Limita los recursos
   - Reduce ecs_desired_count
   - Usa db.t2.micro
   - Desactiva autoscaling

3. **Servicio no disponible**: AWS Academy restringe ciertos servicios
   - Usa EC2 en lugar de Fargate si es necesario
   - Verifica disponibilidad de ECR

4. **IAM permisos denegados**: Academy limita permisos
   - Usa solo servicios permitidos
   - No intentes crear policies personalizadas

---

## 📚 Referencias

- AWS Academy Documentation: [Academy Docs]
- AWS Free Tier vs Academy: Diferentes limitaciones
- Terraform AWS Provider: [Docs]

**Recuerda**: AWS Academy es para aprender, no para producción. Usa configuración simplificada y espera limitaciones.
