# ✅ Pre-Presentación Checklist

## 🎯 Objetivo Final
Demostrar un flujo DevOps completo: Containerización → CI/CD → Deployment en AWS

---

## 📋 Checklist Técnico

### Local Environment Setup
- [ ] Docker Desktop instalado y corriendo
- [ ] Git configurado
- [ ] Repositorio clonado
- [ ] Scripts con permisos: `chmod +x scripts/*.sh`
- [ ] `docker-compose up` funciona sin errores
- [ ] Todos los servicios saludables: `docker-compose ps`

### URLs Funcionales
- [ ] Frontend: http://localhost ✅
- [ ] Ventas API: http://localhost:8080 ✅
- [ ] Despacho API: http://localhost:8081 ✅
- [ ] Swagger Ventas: http://localhost:8080/swagger-ui.html ✅
- [ ] Swagger Despacho: http://localhost:8081/swagger-ui.html ✅
- [ ] Health endpoint: http://localhost/health ✅

### Database Testing
- [ ] MySQL conecta sin errores
- [ ] Base de datos "innovatechdb" existe
- [ ] Tablas creadas correctamente
- [ ] Datos de prueba insertados (opcional)

### Docker Images
- [ ] Verificar tamaños:
  ```bash
  docker images | grep innovatech
  ```
- [ ] Tamaños esperados:
  - [ ] ventas-api: ~500MB
  - [ ] despacho-api: ~450MB
  - [ ] frontend: ~120MB

---

## 🔧 AWS Setup (Si vas a demostrar)

### AWS Account
- [ ] Cuenta AWS creada
- [ ] Acceso a AWS Console verificado
- [ ] AWS CLI instalado
- [ ] AWS credentials configurados: `aws configure`

### IAM & Security
- [ ] IAM User creado para GitHub
- [ ] Access Keys generadas
- [ ] OIDC Provider configurado (si aplica)
- [ ] Role github-actions-ecr creado

### ECR (Elastic Container Registry)
- [ ] Repositorios creados:
  - [ ] innovatech/ventas-api
  - [ ] innovatech/despacho-api
  - [ ] innovatech/frontend

### EC2 Instance
- [ ] Instancia lanzada (t3.medium o superior)
- [ ] Key Pair descargado y con permisos: `chmod 600 innovatech-key.pem`
- [ ] Security Group abierto (puertos 22, 80, 443)
- [ ] IP pública anotada: ___________

### SSH Connectivity
- [ ] Puedo conectar: `ssh -i innovatech-key.pem ec2-user@IP`
- [ ] Docker está instalado en EC2
- [ ] docker-compose está disponible
- [ ] AWS CLI configurado en EC2

---

## 📦 GitHub Actions Configuration

### Repository Settings
- [ ] Branch 'main' creado
- [ ] Repositorio público o con acceso apropiado
- [ ] Workflows habilitados en GitHub

### Secrets Configurados
- [ ] AWS_ACCOUNT_ID
- [ ] AWS_ROLE_TO_ASSUME (si usas OIDC) O AWS_ACCESS_KEY_ID
- [ ] AWS_SECRET_ACCESS_KEY (si usas keys)
- [ ] EC2_SSH_PRIVATE_KEY
- [ ] VITE_API_URL_VENTAS
- [ ] VITE_API_URL_DESPACHOS

### Workflows
- [ ] build-and-test.yml presente
- [ ] push-to-ecr.yml presente
- [ ] deploy-ec2.yml presente
- [ ] Al menos 1 successful run de cada

---

## 🎬 Presentación Material

### Documentos Preparados
- [ ] QUICK_START.md - Para público no-técnico
- [ ] DEPLOYMENT_GUIDE.md - Guía completa
- [ ] PRESENTATION_GUIDE.md - Notas para defensa
- [ ] TESTING_GUIDE.md - Ejemplos de testing
- [ ] DEVOPS_README.md - Resumen proyecto

### Slides/Presentación
- [ ] Slide 1: Portada
- [ ] Slide 2: Problemática & Solución
- [ ] Slide 3: Arquitectura
- [ ] Slide 4: Dockerización
- [ ] Slide 5: CI/CD Pipeline
- [ ] Slide 6: AWS Deployment
- [ ] Slide 7: Monitoreo
- [ ] Slide 8: Métricas & Resultados
- [ ] Slide 9: Q&A

### Demos Preparadas
- [ ] Demo 1: Mostrar docker-compose.yml
- [ ] Demo 2: Ejecutar `docker-compose ps`
- [ ] Demo 3: Mostrar URLs funcionando
- [ ] Demo 4: Mostrar logs
- [ ] Demo 5: Mostrar GitHub Actions workflow
- [ ] Demo 6: Mostrar ECR en AWS Console
- [ ] Demo 7: Mostrar EC2 instancia
- [ ] Demo 8: Curl a endpoints

---

## 🖥️ Equipo & Ambiente

### Hardware
- [ ] Laptop/PC con batería cargada
- [ ] Adaptador HDMI/USB-C disponible
- [ ] Mouse y teclado (backup)
- [ ] Extensión de corriente

### Software
- [ ] VS Code abierto y con proyecto
- [ ] Terminal (PowerShell, Bash, o Git Bash) abierta
- [ ] AWS Console abierta en navegador (si aplica)
- [ ] GitHub abierto en navegador
- [ ] Postman o Insomnia abierto para API testing (opcional)

### Internet & Conectividad
- [ ] Conexión a internet estable
- [ ] VPN desconectada (si causaba problemas)
- [ ] DNS funcionando: `nslookup google.com`

---

## 🎯 Flujo de Presentación

### Minuto 0-2: Introducción
- [ ] Saludar y presentarse
- [ ] Explicar objetivo (10-15 min, DevOps completo)
- [ ] Mostrar agenda

### Minuto 2-4: Arquitectura
- [ ] Mostrar diagrama en PRESENTATION_GUIDE.md
- [ ] Explicar 4 servicios (Nginx, 2 APIs, MySQL)
- [ ] Mostrar docker-compose.yml en VS Code

### Minuto 4-7: Dockerización
- [ ] Abrir Dockerfile de Ventas API
- [ ] Explicar multi-stage build
- [ ] Mostrar seguridad (non-root user)
- [ ] Mostrar health checks
- [ ] DEMO: `docker-compose ps` (mostrar containers saludables)

### Minuto 7-10: CI/CD Pipeline
- [ ] Mostrar workflows en GitHub
- [ ] Explicar trigger: `git push`
- [ ] Mostrar workflow file (build-and-test.yml)
- [ ] Mostrar runs exitosos
- [ ] Explicar: Build → Test → Push ECR

### Minuto 10-12: AWS Deployment
- [ ] Mostrar AWS Console (ECR, EC2)
- [ ] Explicar: Pull images → docker-compose up
- [ ] Mostrar EC2 IP
- [ ] DEMO: `curl http://localhost/health`

### Minuto 12-14: Cierre
- [ ] Resumir puntos clave
- [ ] Mostrar métricas (build time, image size)
- [ ] Preguntas

---

## 📝 Notas Importantes

### Cosas que pueden salir mal
- [ ] Tengo plan B si GitHub Actions está down
- [ ] Tengo backup de screenshots de workflows
- [ ] Tengo grabación de demo local (backup)
- [ ] Conozco troubleshooting básico

### Timing
- [ ] Cada sección ensayada
- [ ] Total 10-15 minutos (margen para Q&A)
- [ ] Transiciones preparadas
- [ ] Buffer de tiempo para preguntas

### Presentación
- [ ] Hablo claro y lentamente
- [ ] Evito jerga técnica innecesaria
- [ ] Doy contexto antes de detalles
- [ ] Hago contacto visual

---

## 🔐 Credenciales Seguras

> **IMPORTANTE**: Nunca mostrar en pantalla:
- [ ] AWS Access Keys
- [ ] AWS Secret Keys
- [ ] SSH Private Keys
- [ ] Database passwords
- [ ] GitHub Personal Access Tokens

**Plan**: Tener credenciales guardadas localmente, no commit al repo

---

## 🎤 Respuestas Preparadas para Preguntas Comunes

### Q: "¿Por qué Docker?"
**R**: Consistency entre entornos, aislamiento de recursos, escalabilidad.

### Q: "¿Por qué GitHub Actions?"
**R**: Integrado con GitHub, free tier generoso, suficiente para CI/CD básico.

### Q: "¿Cuál es el costo en AWS?"
**R**: ~$30-40/mes para esta escala. Producción sería $200-500/mes.

### Q: "¿Cómo escalas esto?"
**R**: ECS/Fargate para orquestación administrada, Load Balancer, Auto Scaling.

### Q: "¿Qué pasa si un container falla?"
**R**: Health checks lo detectan en 30s, Docker lo reinicia automáticamente.

### Q: "¿Cómo mantienes seguridad?"
**R**: Non-root users, secrets en AWS Secrets Manager, OIDC para auth, security headers.

---

## ⏰ Timeline Sugerida

```
Presentación: 15 minutos máximo
├─ 0:00 - 2:00  → Introducción & Arquitectura
├─ 2:00 - 4:00  → Dockerfiles & Containerización  
├─ 4:00 - 7:00  → CI/CD Pipeline
├─ 7:00 - 10:00 → AWS Deployment
├─ 10:00 - 12:00 → Demo Live
└─ 12:00 - 15:00 → Conclusión & Q&A
```

---

## 🚀 Día de Presentación

### Mañana
- [ ] Desayuno ligero
- [ ] Revisa notas de presentación
- [ ] Verifica equipo funciona

### 30 min antes
- [ ] Conecta a wifi/internet
- [ ] Abre todos los programas necesarios
- [ ] Verifica proyector/display
- [ ] Haz test de sound/micrófono

### 10 min antes
- [ ] Respira profundo
- [ ] Reviaja slides mentalmente
- [ ] Verifica postura & ropa
- [ ] Coloca dispositivos de forma visible

### Durante
- [ ] Habla claro y con confianza
- [ ] Mantén ritmo, no corras
- [ ] Si cometes error, sigue adelante con confianza
- [ ] Observa reacciones de audiencia

### Después
- [ ] Agradece a jurado
- [ ] Disponible para preguntas
- [ ] Recopila feedback

---

**¡Buena suerte! 🎯🚀**

**Última revisión:** 2026-05-14  
**Status:** ✅ LISTO PARA PRESENTAR
