# 🚀 QUICK START GUIDE - Testing & AWS Configuration

## ⚡ Testing Local (Sin AWS)

Si solo quieres probar localmente sin AWS, sigue estos pasos:

### 1. Clonar y Setup

```bash
# Clonar repositorio
git clone <tu-repo-url>
cd proyectofullstack2-main

# Hacer ejecutables los scripts (en Git Bash, WSL o Linux)
chmod +x scripts/*.sh
```

### 2. Iniciar Stack Completo

```bash
# Opción A: Usar script (Recomendado)
./scripts/local-dev.sh up

# Opción B: Comando directo
docker-compose up -d
```

### 3. Verificar Estado

```bash
# Ver contenedores corriendo
./scripts/local-dev.sh ps
# o
docker-compose ps

# Debería mostrar:
# CONTAINER           STATUS
# innovatech-mysql    Up (healthy)
# innovatech-ventas-api    Up (healthy)
# innovatech-despacho-api  Up (healthy)
# innovatech-frontend      Up (healthy)
```

### 4. Acceder a Servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Frontend | http://localhost | Interfaz React |
| Ventas API | http://localhost:8080 | API REST Ventas |
| Despacho API | http://localhost:8081 | API REST Despachos |
| Swagger Ventas | http://localhost:8080/swagger-ui.html | Documentación API |
| Swagger Despacho | http://localhost:8081/swagger-ui.html | Documentación API |

### 5. Comandos Útiles

```bash
# Ver logs en tiempo real
./scripts/local-dev.sh logs frontend
./scripts/local-dev.sh logs ventas-api
./scripts/local-dev.sh logs despacho-api

# Conectarse a MySQL
./scripts/local-dev.sh shell mysql
mysql -u innovatech -p
# Contraseña: innovatech123

# Detener servicios
./scripts/local-dev.sh down

# Limpiar todo
./scripts/local-dev.sh clean
```

---

## 🌐 AWS Configuration (Completo)

### Paso 1: Crear Cuenta AWS

1. Ir a https://aws.amazon.com
2. Crear cuenta
3. Verificar email
4. Agregar método de pago

### Paso 2: Crear IAM User

```bash
# 1. Ir a AWS Console → IAM → Users
# 2. Create user: "github-actions"
# 3. Permissions: "AdministratorAccess" (para simplificar, puede reducirse después)
# 4. Create access key: "Command Line Interface (CLI)"
# 5. Guardar:
#    - Access Key ID: AKIA...
#    - Secret Access Key: /wFa...
```

### Paso 3: Configurar AWS CLI Localmente

```bash
# Instalar AWS CLI v2
# Windows: https://awscli.amazonaws.com/AWSCLIV2.msi
# Mac: brew install awscli
# Linux: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Configurar credenciales
aws configure

# Ingresar:
# AWS Access Key ID [None]: AKIA...
# AWS Secret Access Key [None]: /wFa...
# Default region name [None]: us-east-1
# Default output format [None]: json
```

### Paso 4: Crear Repositorios ECR

```bash
# Crear ECR manualmente (vía console) o ejecutar:
./scripts/push-to-ecr.sh

# Script creará:
# ✓ innovatech/ventas-api
# ✓ innovatech/despacho-api
# ✓ innovatech/frontend
```

### Paso 5: Crear Infraestructura EC2

```bash
# Ejecutar script automatizado
./scripts/aws-setup.sh

# Script creará:
# ✓ VPC (Virtual Private Cloud)
# ✓ Subnet
# ✓ Security Group (puertos 22, 80, 443)
# ✓ Key Pair (guardará como innovatech-key.pem)
# ✓ EC2 Instance t3.medium

# Guardar IP pública del output
# Ejemplo: 54.123.45.67
```

### Paso 6: Conectar a EC2 & Configurar

```bash
# Conectar via SSH
ssh -i innovatech-key.pem ec2-user@EC2_PUBLIC_IP

# En la instancia:
cd /home/ec2-user/innovatech
git clone <tu-repo-url> .

# Configurar AWS (para pull de ECR)
aws configure
# Ingresar mismos credentials

# Crear .env
cat > .env << 'EOF'
REGISTRY=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
VERSION=1.0.0
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=innovatechdb
MYSQL_USER=innovatech
MYSQL_PASSWORD=innovatech123
EOF

# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Pull & Deploy
docker-compose pull
docker-compose up -d

# Verificar
docker-compose ps
curl http://localhost/health
```

### Paso 7: Configurar GitHub Actions

#### 7.1 - Crear OIDC Provider en AWS

```bash
# En AWS Console → Identity Providers → Add provider
# 1. Select "OpenID Connect"
# 2. Provider URL: https://token.actions.githubusercontent.com
# 3. Audience: sts.amazonaws.com
# 4. Click Add provider
```

#### 7.2 - Crear IAM Role para GitHub

```bash
# Crear archivo trust-policy.json:
cat > trust-policy.json << 'EOF'
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
EOF

# Crear role
aws iam create-role \
  --role-name github-actions-ecr \
  --assume-role-policy-document file://trust-policy.json

# Adjuntar policy
aws iam attach-role-policy \
  --role-name github-actions-ecr \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Obtener ARN del role
aws iam get-role --role-name github-actions-ecr \
  --query 'Role.Arn' --output text
# Ej: arn:aws:iam::123456789012:role/github-actions-ecr
```

#### 7.3 - Agregar Secrets en GitHub

En tu repositorio → Settings → Secrets and variables → Actions

```
AWS_ACCOUNT_ID=123456789012
AWS_ROLE_TO_ASSUME=arn:aws:iam::123456789012:role/github-actions-ecr
AWS_ACCESS_KEY_ID=AKIA...           (si usas keys)
AWS_SECRET_ACCESS_KEY=/wFa...       (si usas keys)
EC2_SSH_PRIVATE_KEY=-----BEGIN...   (contenido de innovatech-key.pem)
VITE_API_URL_VENTAS=https://api.ejemplo.com/api/ventas
VITE_API_URL_DESPACHOS=https://api.ejemplo.com/api/despachos
```

### Paso 8: Triggear Pipeline CI/CD

```bash
# Hacer un cambio cualquiera
echo "# Test" >> README.md

# Commit y push
git add .
git commit -m "Test CI/CD pipeline"
git push origin main

# GitHub Actions ejecutará automáticamente:
# 1. Build & Test
# 2. Push to ECR
# 3. Deploy to EC2

# Ver progreso en: GitHub → Actions
```

---

## 📊 Verificar Despliegue en AWS

### Via AWS Console

```bash
# Ver instancias
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=innovatech-production" \
  --query 'Reservations[0].Instances[0].[InstanceId,PublicIpAddress,State.Name]' \
  --output table
```

### Via SSH

```bash
# Conectar a instancia
ssh -i innovatech-key.pem ec2-user@IP

# Ver estado
docker-compose ps
docker-compose logs
```

### Via HTTP

```bash
# Probar endpoints
curl http://EC2_PUBLIC_IP/health
curl http://EC2_PUBLIC_IP:8080/swagger-ui.html
curl http://EC2_PUBLIC_IP:8081/swagger-ui.html
```

---

## 💰 Estimar Costos AWS

| Servicio | Tipo | Costo/Mes |
|----------|------|-----------|
| EC2 | t3.medium | ~$30 |
| ECR | Storage (~1GB) | ~$1 |
| Data Transfer | Out | ~$0-5 |
| CloudWatch | Logs | ~$0-2 |
| **TOTAL** | | ~**$33-38** |

*Nota: Usar Free Tier durante 12 meses reduce costos significativamente*

---

## 🔒 Security Best Practices

✅ **Implementado en este proyecto:**

1. **No almacenar secrets en repositorio**
   - Usar GitHub Secrets
   - OIDC para AWS (sin keys almacenadas)

2. **Contenedores non-root**
   - Usuario `appuser` en lugar de root
   - Permisos restrictivos

3. **Network isolation**
   - Security Group solo abre puertos necesarios
   - VPC privada

4. **Logging & Monitoring**
   - CloudWatch logs
   - Container health checks

5. **Versioning**
   - Semantic versioning para imágenes
   - Git tags para releases

---

## 📚 Documentación Importante

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guía completa y detallada
- **[PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md)** - Script para defensa técnica
- **[DEVOPS_README.md](DEVOPS_README.md)** - README de DevOps

---

## ✅ Checklist de Verificación

- [ ] Docker Desktop instalado y corriendo
- [ ] Repositorio clonado
- [ ] Scripts con permisos de ejecución (`chmod +x scripts/*.sh`)
- [ ] `./scripts/local-dev.sh up` funciona sin errores
- [ ] URLs locales accesibles
- [ ] AWS CLI instalado y configurado
- [ ] ECR repositorios creados
- [ ] EC2 instance lanzada
- [ ] GitHub Actions secrets configurados
- [ ] Pipeline CI/CD ejecutado exitosamente

---

## 🆘 Ayuda Rápida

### "No me funciona local"
```bash
# Opción 1: Limpiar todo
./scripts/local-dev.sh clean
./scripts/local-dev.sh up

# Opción 2: Ver qué pasa
docker-compose logs --tail=100
```

### "AWS me dice error de permisos"
```bash
# Verificar credenciales
aws sts get-caller-identity

# Re-configurar
aws configure
```

### "Los workflows no se ejecutan"
```bash
# 1. Verificar secrets en GitHub settings
# 2. Verificar branch es 'main' (no 'master')
# 3. Verificar YAML syntax en .github/workflows/
```

---

**¡Listo! 🎉 Ahora tienes un pipeline DevOps completo.**

¿Preguntas? Ver [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#-troubleshooting)
