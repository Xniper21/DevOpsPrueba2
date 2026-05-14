# Proyecto Semestral - Contenedorización y Despliegue en AWS

Este repositorio contiene:
- `front_despacho`: aplicación frontend React con Vite.
- `back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO`: microservicio backend de despacho.
- `back-Ventas_SpringBoot/Springboot-API-REST`: microservicio backend de ventas.

## Contenedorización

Cada servicio cuenta con su propio `Dockerfile`:
- Frontend: `front_despacho/Dockerfile`
- Backend ventas: `back-Ventas_SpringBoot/Springboot-API-REST/Dockerfile`
- Backend despacho: `back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/Dockerfile`

El frontend usa `multi-stage build` para compilar la app con Node y luego servirla con `nginx`.
Los backends usan un builder Maven y una imagen de runtime `eclipse-temurin:17-jre-alpine`.
Los contenedores se ejecutan con un usuario no root para cumplir buenas prácticas de seguridad.

## Orquestación local

Se agregó un `docker-compose.yml` en la raíz para levantar los servicios juntos:
- `mysql` como base de datos.
- `ventas-api` en `8080`.
- `despacho-api` en `8081`.
- `frontend` en `80`.

Para levantar la solución localmente:

```bash
cd c:\Users\Duoc\Desktop\proyecto semestral
docker compose up --build
```

## Variables de entorno del frontend

Se agregó `front_despacho/.env.example` con las variables:
- `VITE_API_URL_VENTAS`
- `VITE_API_URL_DESPACHOS`

Esto permite que el frontend consuma los microservicios mediante URLs configurables en tiempo de build.

## CI/CD con GitHub Actions

Se creó el flujo de despliegue en `.github/workflows/deploy.yml`.
El pipeline se activa con pushes a la rama `deploy`.

Fases del pipeline:
1. Build de las imágenes Docker de frontend y backends.
2. Push de las imágenes a Docker Hub.
3. Despliegue automático en EC2 mediante SSH.

## Secrets requeridos en GitHub

Los secrets deben definirse en el repositorio:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `DOCKERHUB_REPO`
- `EC2_HOST`
- `EC2_USER`
- `EC2_SSH_KEY`
- `EC2_SSH_PORT` (opcional, default 22)

## Recomendaciones para AWS EC2

Asegúrate de que la instancia EC2 tenga:
- Docker y Docker Compose instalados.
- Puertos abiertos: `80`, `8080`, `8081`.
- Seguridad de red que permita solo el frontend público y mantenga los backends en una red privada dentro del host.

## Cómo usar en la defensa

Durante la presentación puedes explicar:
- Diseño de contenedores y multi-stage builds.
- Uso de variables de entorno y capas optimizadas.
- Orquestación con `docker-compose` y persistencia con volúmenes (`mysql_data`).
- Pipeline CI/CD en GitHub Actions y despliegue automático en EC2.
- Control de secrets para credenciales AWS y Docker Hub.
