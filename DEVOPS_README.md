# 📦 Innovatech FullStack - DevOps & Containerization Project

[![Build and Test](https://github.com/YOUR_ORG/proyectofullstack2/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/YOUR_ORG/proyectofullstack2/actions/workflows/build-and-test.yml)
[![Push to ECR](https://github.com/YOUR_ORG/proyectofullstack2/actions/workflows/push-to-ecr.yml/badge.svg)](https://github.com/YOUR_ORG/proyectofullstack2/actions/workflows/push-to-ecr.yml)

## 🎯 Descripción del Proyecto

Proyecto completo de contenedorización con Docker, CI/CD automatizado con GitHub Actions y deployment en AWS EC2 con ECR.

**Stack Tecnológico:**
- Backend 1: Spring Boot 3.4.4 (API Ventas)
- Backend 2: Spring Boot 3.4.4 (API Despachos)
- Frontend: React 18 + Vite
- Database: MySQL 8.0
- Orchestration: Docker Compose
- CI/CD: GitHub Actions
- Registry: AWS ECR
- Hosting: AWS EC2

---

## 🚀 Quick Start

### Prerrequisitos
- Docker Desktop instalado
- Git instalado

### Inicio en 3 pasos

```bash
# 1. Clonar y entrar
git clone <url-repo>
cd proyectofullstack2-main

# 2. Hacer ejecutables los scripts
chmod +x scripts/*.sh

# 3. Iniciar todo
./scripts/local-dev.sh up
```

**¡Listo!** Accede a:
- 🌐 Frontend: http://localhost
- 🔌 Ventas API: http://localhost:8080
- 📦 Despacho API: http://localhost:8081

---

## 📁 Estructura del Proyecto

```
.
├── back-Ventas_SpringBoot/           # Backend Ventas
│   └── Springboot-API-REST/
│       ├── Dockerfile                # ✨ Multi-stage, optimizado
│       ├── pom.xml
│       └── src/
├── back-Despachos_SpringBoot/        # Backend Despachos
│   └── Springboot-API-REST-DESPACHO/
│       ├── Dockerfile                # ✨ Multi-stage, optimizado
│       ├── pom.xml
│       └── src/
├── front_despacho/                   # Frontend React
│   ├── Dockerfile                    # ✨ Multi-stage
│   ├── nginx.conf                    # ✨ Configuración Nginx optimizada
│   ├── package.json
│   └── src/
├── scripts/                          # 🤖 Scripts de utilidad
│   ├── local-dev.sh                 # Gestión local
│   ├── push-to-ecr.sh               # Push a AWS ECR
│   ├── aws-setup.sh                 # Setup infraestructura AWS
│   └── ec2-setup.sh                 # Setup instancia EC2
├── .github/workflows/                # ⚙️ GitHub Actions
│   ├── build-and-test.yml           # Build + Tests
│   ├── push-to-ecr.yml              # Publicar en ECR
│   └── deploy-ec2.yml               # Deploy a EC2
├── docker-compose.yml                # ✨ Orquestación
├── .env                              # Variables de entorno
├── DEPLOYMENT_GUIDE.md               # 📖 Guía completa
└── PRESENTATION_GUIDE.md             # 🎤 Guía de presentación
```

---

## 🎮 Comandos Principales

### Desarrollo Local

```bash
# Iniciar
./scripts/local-dev.sh up

# Ver logs en vivo
./scripts/local-dev.sh logs frontend

# Ver estado de contenedores
./scripts/local-dev.sh ps

# Reiniciar
./scripts/local-dev.sh restart

# Limpiar todo
./scripts/local-dev.sh clean

# Shell en contenedor
./scripts/local-dev.sh shell mysql
```

### AWS & Deployment

```bash
# Configurar AWS
aws configure

# Setup infraestructura (VPC, EC2, etc)
./scripts/aws-setup.sh

# Push imágenes a ECR
./scripts/push-to-ecr.sh v1.0.0

# Conectar a EC2
ssh -i innovatech-key.pem ec2-user@IP

# Deploy manual (en EC2)
docker-compose up -d
```

---

## 🔄 CI/CD Workflows

### build-and-test.yml
**Trigger:** `git push` a `main` o `develop`, `pull_request`

```yaml
✓ Build Maven projects
✓ Build Frontend (Vite)
✓ Run all tests
✓ Lint code
✓ Build Docker images
```

### push-to-ecr.yml
**Trigger:** `git push main`, `tags` (v*)

```yaml
✓ Build images optimizadas
✓ Login a AWS ECR
✓ Push con versionado automático
✓ Create deployment summary
```

### deploy-ec2.yml
**Trigger:** Manual o automático

```yaml
✓ Get EC2 IP by tag
✓ SSH to instance
✓ Pull latest images
✓ docker-compose up
✓ Health checks
```

---

## 🐳 Docker Optimizaciones Implementadas

### Seguridad
- ✅ Non-root users (appuser)
- ✅ Security headers en Nginx
- ✅ OIDC authentication para AWS
- ✅ Secret management

### Performance
- ✅ Multi-stage builds (reduce tamaño 80%)
- ✅ JVM optimizations para containers
- ✅ Nginx compression & caching
- ✅ Alpine base images

### Reliability
- ✅ Health checks en todos los servicios
- ✅ Restart policies
- ✅ Resource limits
- ✅ Structured logging
- ✅ Health endpoints

---

## 📊 Arquitectura de Despliegue

```
┌─────────────────────────────────────┐
│  GitHub Repository                  │
│  (Source Code)                      │
└──────────────┬──────────────────────┘
               │ git push
               ▼
┌─────────────────────────────────────┐
│  GitHub Actions CI/CD               │
│  ├─ Build Docker images             │
│  ├─ Run tests                       │
│  ├─ Push to ECR                     │
│  └─ Deploy to EC2                   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  AWS ECR (Container Registry)       │
│  ├─ innovatech/ventas-api:latest   │
│  ├─ innovatech/despacho-api:latest │
│  └─ innovatech/frontend:latest     │
└──────────────┬──────────────────────┘
               │ docker pull
               ▼
┌─────────────────────────────────────┐
│  AWS EC2 Instance                   │
│  ├─ Docker Compose                  │
│  ├─ Nginx (Frontend)                │
│  ├─ Spring Boot APIs                │
│  └─ MySQL Database                  │
└─────────────────────────────────────┘
```

---

## 📖 Documentación

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guía completa de deployment
- **[PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md)** - Guía para defensa técnica (10-15 min)

---

## 🔐 Seguridad

### Configuración AWS

Necesario configurar secrets en GitHub:
```
AWS_ACCOUNT_ID
AWS_ROLE_TO_ASSUME
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
EC2_SSH_PRIVATE_KEY
VITE_API_URL_VENTAS
VITE_API_URL_DESPACHOS
```

### Best Practices Implementadas
- ✅ OIDC para AWS (no almacenar credentials)
- ✅ Non-root containers
- ✅ Network isolation
- ✅ Resource limits
- ✅ Health checks

---

## 🐛 Troubleshooting

### Contenedores no inician
```bash
./scripts/local-dev.sh clean
./scripts/local-dev.sh up
```

### Ver logs de error
```bash
docker-compose logs --tail=50 ventas-api
```

### Reset database
```bash
docker volume rm innovatechdb_mysql_data
./scripts/local-dev.sh restart
```

Ver más en [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#-troubleshooting)

---

## 📈 Métricas & Performance

| Métrica | Valor |
|---------|-------|
| Build Time | ~3-4 min |
| Deployment Time | ~5 min |
| Ventas API Image | ~500MB |
| Despacho API Image | ~450MB |
| Frontend Image | ~120MB |
| EC2 Startup | ~2 min |

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crear rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

---

## 📝 Licencia

Este proyecto está bajo licencia MIT.

---

## 👨‍💼 Autor

Ignacio García - DevOps & Full Stack Developer

---

## 🔗 Links Útiles

- [Docker Documentation](https://docs.docker.com/)
- [AWS ECR Guide](https://docs.aws.amazon.com/ecr/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Spring Boot Reference](https://spring.io/projects/spring-boot)
- [React Documentation](https://react.dev/)

---

**Last Updated:** 2026-05-14  
**Version:** 1.0.0
