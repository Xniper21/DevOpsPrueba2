# 🚀 DevOps - Guía Completa de Deployment

## 📋 Tabla de Contenidos

1. [Arquitectura](#arquitectura)
2. [Prerrequisitos](#prerrequisitos)
3. [Desarrollo Local](#desarrollo-local)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [AWS ECR Setup](#aws-ecr-setup)
6. [Deployment en EC2](#deployment-en-ec2)
7. [Monitoreo y Logs](#monitoreo-y-logs)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     GitHub (Repository)                 │
└──────────────────────┬──────────────────────────────────┘
                       │ git push
                       ▼
┌─────────────────────────────────────────────────────────┐
│              GitHub Actions (CI/CD Pipeline)            │
│  ┌─────────────────────────────────────────────────┐    │
│  │  1. Build (Maven + Node.js)                     │    │
│  │  2. Test (Unit & Integration)                   │    │
│  │  3. Lint & Code Quality                         │    │
│  │  4. Build Docker Images                         │    │
│  │  5. Push to ECR                                 │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────┬──────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
    ┌─────────┐ ┌──────────┐ ┌──────────┐
    │  ECR    │ │   ECR    │ │   ECR    │
    │Ventas   │ │Despacho  │ │Frontend  │
    └─────────┘ └──────────┘ └──────────┘
         │             │             │
         └─────────────┼─────────────┘
                       │
                       ▼
    ┌──────────────────────────────────┐
    │  AWS EC2 Instance (Docker Host)  │
    │  ┌────────────────────────────┐  │
    │  │   docker-compose up        │  │
    │  │  ┌────────────────────┐    │  │
    │  │  │  nginx (Frontend)  │    │  │
    │  │  │  - Port 80         │    │  │
    │  │  └────────────────────┘    │  │
    │  │  ┌────────────────────┐    │  │
    │  │  │ Spring Boot APIs   │    │  │
    │  │  │ - Ventas (8080)    │    │  │
    │  │  │ - Despacho (8081)  │    │  │
    │  │  └────────────────────┘    │  │
    │  │  ┌────────────────────┐    │  │
    │  │  │  MySQL Database    │    │  │
    │  │  │ - Port 3306        │    │  │
    │  │  └────────────────────┘    │  │
    │  └────────────────────────────┘  │
    └──────────────────────────────────┘
           │
           ▼
    ┌──────────────────────┐
    │  CloudWatch Logs     │
    │  Monitoring          │
    └──────────────────────┘
```

---

## 📦 Prerrequisitos

### Sistema Local
- **Docker Desktop**: [Descargar](https://www.docker.com/products/docker-desktop)
- **Git**: [Descargar](https://git-scm.com/)
- **AWS CLI v2**: [Descargar](https://aws.amazon.com/cli/)
- **Maven**: 3.8+
- **Node.js**: 20+

### AWS Accounts & Access
- Cuenta de AWS activa
- AWS IAM User con permisos para:
  - EC2 (create/manage instances)
  - ECR (create/push repositories)
  - CloudWatch (logs)
  - IAM (roles/policies)

---

## 🏠 Desarrollo Local

### Inicio Rápido

```bash
# Clonar repositorio
git clone <url-repo>
cd proyectofullstack2-main

# Hacer ejecutables los scripts
chmod +x scripts/*.sh

# Iniciar entorno completo
./scripts/local-dev.sh up
```

### URLs de Acceso Local

| Servicio | URL | Usuario/Contraseña |
|----------|-----|-------------------|
| Frontend | `http://localhost` | - |
| Ventas API | `http://localhost:8080` | - |
| Despacho API | `http://localhost:8081` | - |
| MySQL | `localhost:3306` | `innovatech / innovatech123` |

### Gestionar Entorno Local

```bash
# Ver logs en tiempo real
./scripts/local-dev.sh logs frontend

# Acceder a shell de contenedor
./scripts/local-dev.sh shell mysql

# Reiniciar todos los servicios
./scripts/local-dev.sh restart

# Limpiar todo (containers, volúmenes)
./scripts/local-dev.sh clean
```

---

## 🔄 CI/CD Pipeline

### Workflows Automatizados

#### 1. **build-and-test.yml**
Ejecuta en: `push` a `main` o `develop`, `pull_request`

```yaml
Pasos:
├── Checkout
├── Setup Docker Buildx
├── Build Ventas API
├── Build Despacho API
├── Build Frontend
└── Test (Backend + Frontend)
```

#### 2. **push-to-ecr.yml**
Ejecuta en: `push` a `main`, `tags` (v*)

```yaml
Pasos:
├── Login a ECR
├── Build images con versión
├── Push a AWS ECR
└── Create deployment summary
```

#### 3. **deploy-ec2.yml**
Ejecuta: Manual o después de push

```yaml
Pasos:
├── Configure AWS credentials
├── Get EC2 instance IP
├── SSH to instance
├── Pull latest images
├── docker-compose up
└── Health checks
```

### Configurar Secrets en GitHub

Ir a: `Settings → Secrets and variables → Actions`

```
AWS_ACCOUNT_ID                = 123456789012
AWS_ROLE_TO_ASSUME            = arn:aws:iam::123456789012:role/github-actions-role
AWS_ACCESS_KEY_ID             = AKIA...
AWS_SECRET_ACCESS_KEY         = /wFa...
EC2_SSH_PRIVATE_KEY           = -----BEGIN OPENSSH PRIVATE KEY-----...
VITE_API_URL_VENTAS          = https://api.innovatech.com/api/ventas
VITE_API_URL_DESPACHOS       = https://api.innovatech.com/api/despachos
```

---

## 🗂️ AWS ECR Setup

### Paso 1: Configurar AWS CLI

```bash
aws configure

# Ingresar:
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: /wFa...
# Default region name: us-east-1
# Default output format: json
```

### Paso 2: Crear Repositorios ECR

```bash
# Ejecutar script automatizado
./scripts/push-to-ecr.sh v1.0.0

# O manualmente:
aws ecr create-repository \
  --repository-name innovatech/ventas-api \
  --region us-east-1 \
  --encryption-configuration encryptionType=AES
```

### Paso 3: Configurar IAM Role para GitHub Actions

```bash
# Crear trust policy (trust-policy.json):
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}

# Crear role
aws iam create-role --role-name github-actions-role \
  --assume-role-policy-document file://trust-policy.json

# Adjuntar permisos
aws iam attach-role-policy --role-name github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

---

## 🚀 Deployment en EC2

### Paso 1: Crear Infraestructura AWS

```bash
# Configurar variables (opcional)
export AWS_REGION=us-east-1
export INSTANCE_TYPE=t3.medium
export KEY_PAIR_NAME=innovatech-key

# Ejecutar setup
./scripts/aws-setup.sh

# Script creará:
# ✓ VPC
# ✓ Subnet
# ✓ Security Group (puertos 22, 80, 443)
# ✓ Key Pair
# ✓ EC2 Instance t3.medium
# ✓ User data con Docker instalado
```

### Paso 2: Conectar a Instancia

```bash
# Obtener IP pública
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=innovatech-production" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Conectar via SSH
ssh -i innovatech-key.pem ec2-user@EC2_PUBLIC_IP

# En la instancia, clonar repositorio
cd /home/ec2-user/innovatech
git clone <url-repo> .

# Configurar AWS credentials
aws configure
```

### Paso 3: Deploy Manual

```bash
# Desde la instancia EC2
cd /home/ec2-user/innovatech

# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Crear archivo .env
cat > .env << 'EOF'
REGISTRY=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
VERSION=1.0.0
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=innovatechdb
MYSQL_USER=innovatech
MYSQL_PASSWORD=innovatech123
EOF

# Pull & Deploy
docker-compose pull
docker-compose up -d

# Verificar estado
docker-compose ps
curl http://localhost/health
```

### Paso 4: Deploy Automático (GitHub Actions)

```bash
# En el repositorio, triggear workflow
git push main

# GitHub Actions hará automáticamente:
# 1. Build images
# 2. Push a ECR
# 3. Deploy a EC2 via SSH
# 4. Verificar health checks
```

---

## 📊 Monitoreo y Logs

### Ver Logs Locales

```bash
# Todos los servicios
docker-compose logs

# Servicio específico (follow mode)
docker-compose logs -f frontend

# Últimas 100 líneas
docker-compose logs --tail=100 ventas-api
```

### Logs en CloudWatch (AWS)

```bash
# Listar log groups
aws logs describe-log-groups --region us-east-1

# Ver logs
aws logs tail /aws/ec2/innovatech --follow
```

### Health Checks

```bash
# Verificar salud de servicios
curl http://localhost/health              # Frontend
curl http://localhost:8080/swagger-ui.html # Ventas API
curl http://localhost:8081/swagger-ui.html # Despacho API
```

### Monitoring Avanzado

Considerar agregar:
- **Prometheus**: Métricas
- **Grafana**: Dashboards
- **ELK Stack**: Análisis de logs
- **New Relic**: APM

---

## 🐛 Troubleshooting

### Problema: Contenedores no inician

```bash
# Ver logs detallados
docker-compose logs

# Verificar recursos
docker stats

# Reiniciar servicio específico
docker-compose restart ventas-api

# Limpiar y reintentar
./scripts/local-dev.sh clean
./scripts/local-dev.sh up
```

### Problema: Base de datos no conecta

```bash
# Verificar MySQL está corriendo
docker-compose ps mysql

# Conectar directamente
docker exec -it innovatech-mysql mysql -u innovatech -p

# Verificar variables de entorno
docker-compose exec ventas-api env | grep DB_
```

### Problema: API retorna 502 Bad Gateway

```bash
# Verificar que APIs estén corriendo
docker-compose ps

# Ver logs de APIs
docker-compose logs ventas-api
docker-compose logs despacho-api

# Verificar Nginx
docker-compose logs frontend

# Probar conexión directa
curl http://localhost:8080/swagger-ui.html
```

### Problema: Permisos SSH para EC2

```bash
# Permisos correctos para key
chmod 600 innovatech-key.pem

# Si falla, regenerar
aws ec2 delete-key-pair --key-name innovatech-key
./scripts/aws-setup.sh
```

### Problema: ECR Push falla

```bash
# Verificar credenciales
aws sts get-caller-identity

# Re-login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Verificar repositorio existe
aws ecr describe-repositories --region us-east-1
```

---

## 📈 Optimizaciones Implementadas

### Security (Seguridad)
- ✅ Non-root users en contenedores
- ✅ SecurityContext en K8s
- ✅ Network policies
- ✅ Secret management
- ✅ Security headers (Nginx)

### Performance (Rendimiento)
- ✅ Multi-stage Dockerfiles (menores tamaños)
- ✅ JVM optimizations para containers
- ✅ Nginx compression & caching
- ✅ Database connection pooling
- ✅ CDN para static assets

### Reliability (Confiabilidad)
- ✅ Health checks en todos los servicios
- ✅ Restart policies
- ✅ Resource limits
- ✅ Logging structured
- ✅ Monitoring & Alerting

### Cost Optimization
- ✅ Alpine images (menores)
- ✅ Layer caching en Docker
- ✅ Resource requests optimizados
- ✅ Auto-scaling ready

---

## 🔗 Referencias y Recursos

- [Docker Documentation](https://docs.docker.com/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Specification](https://github.com/compose-spec/compose-spec)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

**Última actualización:** 2026-05-14  
**Versión:** 1.0.0
