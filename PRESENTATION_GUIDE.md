# 🎯 Guía de Presentación - DevOps & Containerización

**Duración:** 10-15 minutos  
**Estructura:** 4 bloques temáticos  

---

## 📍 BLOQUE 1: Introducción & Contexto (2 min)

### Apertura
> "Buenos días, voy a presentar el ciclo completo de DevOps que implementé en nuestro proyecto fullstack, desde la containerización hasta el deployment en AWS con CI/CD automatizado."

### Puntos Clave
- **Problema**: Necesidad de deployar aplicación con múltiples servicios (Backend Java, Backend Java, Frontend React)
- **Solución**: Implementar Docker + Orquestación + CI/CD
- **Objetivo**: Automatizar builds, tests y deployments

### Slide Mental
```
Local Dev → Testing → Build → Push ECR → Deploy EC2
                              (Automation)
```

---

## 🏗️ BLOQUE 2: Arquitectura & Containerización (4 min)

### 2.1 - Arquitectura de Contenedores

**Mostrar**: Diagrama de arquitectura del archivo DEPLOYMENT_GUIDE.md

```
Frontend (Nginx)     ← Distribución estática + Proxy
   ↓
Ventas API (Java)    ← Spring Boot + MySQL
Despacho API (Java)  ← Spring Boot + MySQL
   ↓
MySQL Database       ← Datos compartidos
```

**Explicar**:
- "Cada servicio en su propio contenedor para aislamiento"
- "Nginx actúa como reverse proxy y sirve frontend"
- "APIs conectan a base de datos compartida"

### 2.2 - Dockerfiles Optimizados

**Mostrar**: Dockerfile de Ventas

**Puntos a Destacar**:

1. **Multi-stage build**
   ```dockerfile
   Stage 1: builder     → Compila JAR con Maven (pesado)
   Stage 2: runtime    → Solo JRE + JAR (ligero)
   ```
   - "Reducimos tamaño final de ~2.5GB a ~500MB"

2. **Security - Usuario no-root**
   ```dockerfile
   USER appuser        → Menos permisos = Más seguro
   ```
   - "Principio de least privilege"

3. **Health Checks**
   ```dockerfile
   HEALTHCHECK        → Docker monitorea salud del contenedor
   ```
   - "Reinicio automático si falla"

4. **JVM Optimization**
   ```dockerfile
   -XX:+UseContainerSupport      → Detecta límites de container
   -XX:MaxRAMPercentage=75       → Usa solo 75% de memoria
   ```
   - "Java aware de estar en container"

### 2.3 - Docker Compose

**Archivo**: docker-compose.yml

**Explicar**:
- "Levanta todos los servicios con una sola línea: `docker-compose up`"
- "Define networking automático entre servicios"
- "Persistence con volúmenes"
- "Health checks coordinados"

**Demo Mental**:
```bash
$ docker-compose up
Creating innovatech-mysql ...
Creating innovatech-ventas-api ...
Creating innovatech-despacho-api ...
Creating innovatech-frontend ...

✓ All services running
```

---

## 🔄 BLOQUE 3: CI/CD Pipeline (4 min)

### 3.1 - Flujo Completo

**Mostrar**: Diagrama en DEPLOYMENT_GUIDE.md

```
git push main
    ↓
GitHub Actions Trigger
    ├─ Build (Maven + Node.js)
    ├─ Test (Unit + Integration)
    ├─ Build Docker Images
    ├─ Push to ECR
    └─ Deploy to EC2
```

### 3.2 - Workflow: build-and-test.yml

**Proceso**:
1. Checkout código
2. Build Ventas API (Maven)
3. Build Despacho API (Maven)
4. Build Frontend (Vite)
5. Run tests (Maven test, ESLint)

**Resultado**: ✅ Build pasado → Almacenar artefactos

### 3.3 - Workflow: push-to-ecr.yml

**Requisitos**: Secrets en GitHub
```
AWS_ACCOUNT_ID
AWS_ROLE_TO_ASSUME
VITE_API_URL_VENTAS
VITE_API_URL_DESPACHOS
```

**Proceso**:
1. AWS credentials (OIDC - Sin almacenar secrets)
2. Login a ECR
3. Build images con versioning automático
4. Push a AWS ECR

**Beneficio**: 
- "Versionado automático por SHA de commit"
- "OIDC más seguro que API keys"

### 3.4 - Workflow: deploy-ec2.yml

**Trigger**: Manual o automático

**Proceso**:
1. Get instance IP por tag
2. SSH a EC2
3. Pull images from ECR
4. `docker-compose up -d`
5. Health checks

**Resultado**: ✅ Aplicación desplegada y funcionando

---

## ☁️ BLOQUE 4: AWS Deployment & DevOps (4 min)

### 4.1 - Infraestructura AWS

**Script**: aws-setup.sh (automatizado)

**Componentes creados**:
```
VPC (10.0.0.0/16)
  ├─ Subnet (10.0.1.0/24)
  ├─ Security Group (puertos 22, 80, 443)
  ├─ Key Pair (SSH)
  └─ EC2 Instance (t3.medium)
```

**Tiempo**: ~5 minutos de setup automático

### 4.2 - ECR (Elastic Container Registry)

**Ventajas**:
- Integrado con AWS
- Control de acceso IAM
- Lifecycle policies (limpiar imágenes viejas)
- Scanning de vulnerabilidades

**Estructura**:
```
innovatech/ventas-api:latest
innovatech/ventas-api:v1.0.0
innovatech/ventas-api:abc1234567
```

### 4.3 - EC2 Deployment

**Setup con user-data**:
- Docker instalado automáticamente
- docker-compose descargado
- Systemd service configurado
- CloudWatch agent para logs

**Deploy**:
```bash
ssh -i innovatech-key.pem ec2-user@INSTANCE_IP
cd /home/ec2-user/innovatech
docker-compose up -d
```

### 4.4 - Monitoreo & Logs

**Capas de logs**:
1. Docker logs → `docker-compose logs`
2. CloudWatch → `aws logs tail`
3. Application logs → Nginx access/error, Spring Boot

**Health Endpoints**:
- Frontend: `http://IP/health`
- Ventas: `http://IP:8080/swagger-ui.html`
- Despacho: `http://IP:8081/swagger-ui.html`

---

## 💡 BLOQUE 5: Decisiones Técnicas & Justificación (2 min)

### ¿Por qué Docker?
- Consistency (mismo en dev, staging, prod)
- Portabilidad
- Escalabilidad
- Aislamiento de recursos

### ¿Por qué CI/CD?
- Automatización = menos errores
- Faster feedback
- Deployments más seguros
- Auditoría completa

### ¿Por qué ECR?
- Integración nativa con AWS
- Security (scanning vulnerabilidades)
- Performance (transfer rápido a EC2)

### ¿Por qué docker-compose?
- Desarrollo local similar a producción
- Orquestación simple vs Kubernetes
- Suficiente para aplicación de escala media

---

## 🎬 FINAL: Cierre & Q&A (1-2 min)

### Resumen Ejecutivo

> "He implementado un flujo DevOps completo que automatiza el ciclo de vida de nuestra aplicación:
> 
> 1. **Containerización**: Cada servicio aislado y optimizado
> 2. **Automatización**: GitHub Actions ejecuta tests y builds automáticamente
> 3. **Deployment**: ECR para almacenamiento seguro, EC2 para hosting
> 4. **Monitoreo**: Health checks y logging en todas las capas
> 
> Todo integrado para que con un simple `git push`, la aplicación se testee, se empaquete, se publique y se despliegue automáticamente."

### Demostraciones Posibles (si hay tiempo)

```bash
# 1. Mostrar local running
docker-compose ps

# 2. Mostrar logs
docker-compose logs frontend

# 3. Mostrar URLs funcionando
curl http://localhost/health

# 4. Mostrar GitHub Actions runs
# (ir a repository → Actions)

# 5. Mostrar ECR repositories
aws ecr describe-repositories
```

### Preguntas Potenciales & Respuestas

**P**: "¿Por qué no usaste Kubernetes?"  
**R**: "Kubernetes es más complejo y costoso. Docker Compose es suficiente para esta escala. Kubernetes sería para miles de requests o múltiples datacenters."

**P**: "¿Cómo escalas si crece el tráfico?"  
**R**: "Podríamos usar Auto Scaling Groups en AWS, o migrar a ECS/Fargate para orquestación administrada."

**P**: "¿Qué pasa si un contenedor falla?"  
**R**: "Health checks lo detectan en 30 segundos, Docker lo reinicia automáticamente. En producción, CloudWatch alertas notificarían."

**P**: "¿Cómo manejás secrets?"  
**R**: "Usa AWS Secrets Manager o variables de entorno. GitHub Actions usa OIDC para no almacenar keys. Nunca en el código."

**P**: "¿Costo aproximado en AWS?"  
**R**: "t3.medium ~$0.04/hora. Estimado ~$30/mes para desarrollo. Producción necesitaría Load Balancer + Auto Scaling (~$200-500/mes)."

---

## 🎨 Presentación Visual - Slides Clave

### Slide 1: Title
```
╔═══════════════════════════════════════════════╗
║                                               ║
║        DevOps & Containerización             ║
║        Proyecto Innovatech FullStack         ║
║                                               ║
║        Docker → GitHub Actions → AWS ECR     ║
║        → EC2 Deployment                      ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

### Slide 2: Architecture
(Mostrar diagrama del DEPLOYMENT_GUIDE.md)

### Slide 3: CI/CD Pipeline
(Git push → Build → Test → Push ECR → Deploy)

### Slide 4: Key Metrics
```
Performance:
  • Build time: ~3-4 min
  • Deployment time: ~5 min
  • Image size: 500MB (ventas), 450MB (despacho), 120MB (frontend)

Security:
  • Health checks: ✓
  • Non-root users: ✓
  • Security headers: ✓
  • OIDC auth: ✓

Automation:
  • 100% CI/CD
  • 0 manual deployment steps
  • Rollback automático en health check failures
```

---

## ✅ Checklist Pre-Presentación

- [ ] Conectado a internet
- [ ] Repositorio clonado localmente
- [ ] `docker-compose up` funcionando
- [ ] GitHub Actions visible y con runs exitosos
- [ ] AWS console abierta (opcional)
- [ ] Scripts ejecutables en demostración
- [ ] Backup de diapositivas/notas
- [ ] Micrófono y audio funcionando

---

**¡Buena suerte en la presentación! 🚀**
