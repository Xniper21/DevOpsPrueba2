# 🧪 Testing & API Examples

## 📡 Endpoints Disponibles

### Base URLs

```
Local Development:
- Frontend:     http://localhost
- Ventas API:   http://localhost:8080
- Despacho API: http://localhost:8081

Production (AWS):
- Frontend:     http://EC2_PUBLIC_IP
- Ventas API:   http://EC2_PUBLIC_IP/api/ventas
- Despacho API: http://EC2_PUBLIC_IP/api/despachos
```

---

## 🏥 Health Checks

```bash
# Frontend Health
curl -s http://localhost/health | jq .

# Ventas API Health
curl -s http://localhost:8080/actuator/health | jq .

# Despacho API Health
curl -s http://localhost:8081/actuator/health | jq .
```

---

## 🔍 API Testing

### Swagger Documentation

Acceder directo en navegador:
- Ventas: http://localhost:8080/swagger-ui.html
- Despacho: http://localhost:8081/swagger-ui.html

### Ejemplos cURL

```bash
# ===== VENTAS API =====

# Get all ventas
curl -X GET http://localhost:8080/api/ventas \
  -H "Content-Type: application/json"

# Create new venta
curl -X POST http://localhost:8080/api/ventas \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "VENTA001",
    "monto": 1500.00,
    "estado": "PENDIENTE"
  }'

# Get venta by ID
curl -X GET http://localhost:8080/api/ventas/1 \
  -H "Content-Type: application/json"

# Update venta
curl -X PUT http://localhost:8080/api/ventas/1 \
  -H "Content-Type: application/json" \
  -d '{
    "estado": "COMPLETADA"
  }'

# Delete venta
curl -X DELETE http://localhost:8080/api/ventas/1

# ===== DESPACHO API =====

# Get all despachos
curl -X GET http://localhost:8081/api/despachos \
  -H "Content-Type: application/json"

# Create new despacho
curl -X POST http://localhost:8081/api/despachos \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "DESP001",
    "destino": "Ciudad XYZ",
    "estado": "PENDIENTE"
  }'

# Get despacho by ID
curl -X GET http://localhost:8081/api/despachos/1 \
  -H "Content-Type: application/json"
```

---

## 🧬 Test Automation Examples

### Bash Script para Testing

```bash
#!/bin/bash

# test-api.sh - Script para testing automatizado

BASE_URL="http://localhost:8080"
API="${1:-/api/ventas}"
ENDPOINT="${BASE_URL}${API}"

echo "Testing: $ENDPOINT"
echo ""

# Test 1: Health Check
echo "1. Health Check"
curl -s "${BASE_URL}/actuator/health" | jq .
echo ""

# Test 2: Get All
echo "2. Get All Items"
curl -s -X GET "${ENDPOINT}" \
  -H "Content-Type: application/json" | jq .
echo ""

# Test 3: Create Item
echo "3. Create Item"
RESPONSE=$(curl -s -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "TEST001",
    "monto": 500.00,
    "estado": "NUEVO"
  }')
echo "$RESPONSE" | jq .
ITEM_ID=$(echo "$RESPONSE" | jq -r '.id')
echo ""

# Test 4: Get by ID
echo "4. Get Item by ID: $ITEM_ID"
curl -s -X GET "${ENDPOINT}/${ITEM_ID}" \
  -H "Content-Type: application/json" | jq .
echo ""

# Test 5: Update Item
echo "5. Update Item"
curl -s -X PUT "${ENDPOINT}/${ITEM_ID}" \
  -H "Content-Type: application/json" \
  -d '{
    "estado": "ACTUALIZADO"
  }' | jq .
echo ""

# Test 6: Delete Item
echo "6. Delete Item"
curl -s -X DELETE "${ENDPOINT}/${ITEM_ID}" \
  -H "Content-Type: application/json"
echo ""

echo "✓ Tests completed!"
```

### Ejecutar Tests

```bash
chmod +x test-api.sh
./test-api.sh /api/ventas
./test-api.sh /api/despachos
```

---

## 🧪 Postman Collection

Importar en Postman:

```json
{
  "info": {
    "name": "Innovatech API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Ventas",
      "item": [
        {
          "name": "Get All Ventas",
          "request": {
            "method": "GET",
            "url": {
              "raw": "{{BASE_URL}}/api/ventas",
              "host": ["{{BASE_URL}}"],
              "path": ["api", "ventas"]
            }
          }
        },
        {
          "name": "Create Venta",
          "request": {
            "method": "POST",
            "url": {
              "raw": "{{BASE_URL}}/api/ventas",
              "host": ["{{BASE_URL}}"],
              "path": ["api", "ventas"]
            },
            "body": {
              "mode": "raw",
              "raw": "{\"numero\": \"VENTA001\", \"monto\": 1500.00}"
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "BASE_URL",
      "value": "http://localhost:8080"
    }
  ]
}
```

---

## 📊 Load Testing

### Apache Bench (ab)

```bash
# Instalar
brew install httpd           # Mac
sudo apt-get install apache2-utils  # Linux

# Test simple
ab -n 1000 -c 10 http://localhost:8080/api/ventas

# Test con datos
ab -n 100 -c 5 -p data.json -T application/json \
  http://localhost:8080/api/ventas
```

### k6 (Load Testing)

```bash
# Instalar: https://k6.io/docs/getting-started/installation/

# Script k6 (load-test.js)
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  let response = http.get('http://localhost:8080/api/ventas');
  check(response, {
    'status is 200': (r) => r.status === 200,
  });
}

# Ejecutar
k6 run load-test.js
```

---

## 🔄 Docker Compose Debugging

### Ver Logs

```bash
# Todos los servicios
docker-compose logs

# Servicio específico
docker-compose logs -f ventas-api

# Últimas 50 líneas
docker-compose logs --tail=50 despacho-api

# Logs con timestamp
docker-compose logs -t
```

### Inspeccionar Contenedor

```bash
# Acceder a shell
docker-compose exec ventas-api sh

# Ver variables de entorno
docker-compose exec ventas-api env

# Ver procesos
docker-compose exec ventas-api ps aux

# Ver archivos
docker-compose exec ventas-api ls -la /app
```

### Network Testing

```bash
# Verificar conectividad entre contenedores
docker-compose exec ventas-api ping despacho-api

# Ver network
docker network ls
docker network inspect innovatechdb_innovatech

# DNS resolution
docker-compose exec ventas-api nslookup mysql
```

---

## 🗄️ Database Testing

### Conectar a MySQL

```bash
# Vía docker-compose
docker-compose exec mysql mysql -u innovatech -p

# Contraseña: innovatech123

# Queries útiles
USE innovatechdb;
SHOW TABLES;
SELECT * FROM venta LIMIT 10;
SELECT * FROM despacho LIMIT 10;
```

### Backup & Restore

```bash
# Backup
docker-compose exec mysql mysqldump -u innovatech -p innovatechdb > backup.sql

# Restore
docker-compose exec -T mysql mysql -u innovatech -p < backup.sql
```

---

## 📈 Performance Benchmarks

### Local Testing

```bash
# Benchmark HTTP requests
ab -n 1000 -c 50 http://localhost/health

# Resultado esperado:
# Requests per second: ~500-1000 req/s
# Failed requests: 0
# Mean time per request: ~50ms
```

### Database Query Performance

```bash
# En MySQL shell
SELECT benchmark(1000000, MD5('test'));

# Query de ventas
SELECT COUNT(*) FROM venta;
```

---

## 🐛 Common Issues & Solutions

### 502 Bad Gateway

```bash
# Verificar APIs están corriendo
docker-compose ps

# Ver logs de Nginx
docker-compose logs frontend

# Verificar DNS resolution
docker-compose exec frontend nslookup ventas-api
```

### Connection Refused

```bash
# Verificar puerto está abierto
docker-compose exec ventas-api netstat -tuln

# Verificar firewall
sudo ufw status
```

### Memory Issues

```bash
# Ver uso de recursos
docker stats

# Limitar memoria en docker-compose.yml
services:
  ventas-api:
    deploy:
      resources:
        limits:
          memory: 512M
```

---

## 📝 Test Report Template

```
Test Execution Report
====================

Date: 2026-05-14
Environment: Local Development

Tests Executed:
✓ Health checks: PASSED
✓ API responses: PASSED
✓ Database connectivity: PASSED
✓ Frontend loading: PASSED
✓ Load testing: PASSED (500 req/s)

Issues Found:
- None

Recommendations:
- Consider adding more integration tests
- Implement APM for better monitoring

Signed:
Date:
```

---

## 🔗 References

- [cURL Documentation](https://curl.se/docs/)
- [Postman Documentation](https://learning.postman.com/)
- [Apache Bench Guide](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [k6 Documentation](https://k6.io/docs/)
- [Docker Compose CLI Reference](https://docs.docker.com/compose/reference/)
