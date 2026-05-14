# Getting Started - Windows PowerShell

## ⚡ Super Quick Start (5 min)

### Prerrequisitos
- Docker Desktop instalado y corriendo
- Git instalado
- PowerShell o Git Bash

### Paso 1: Clone & Navigate
```powershell
git clone <tu-repo-url>
cd proyectofullstack2-main
```

### Paso 2: Make Scripts Executable (Git Bash)
```bash
# En Git Bash (no PowerShell)
chmod +x scripts/*.sh
```

### Paso 3: Start Everything
```powershell
# Opción A: Directamente con docker-compose
docker-compose up -d

# Opción B: Con script (en Git Bash)
./scripts/local-dev.sh up
```

### Paso 4: Check Status
```powershell
docker-compose ps

# Debería mostrar:
# CONTAINER           STATUS
# innovatech-mysql    Up (healthy)
# innovatech-ventas-api    Up (healthy)  
# innovatech-despacho-api  Up (healthy)
# innovatech-frontend      Up (healthy)
```

### Paso 5: Access Services
```
Frontend:     http://localhost
Ventas API:   http://localhost:8080
Despacho API: http://localhost:8081
```

**✅ ¡Listo!** 

---

## 🛑 Stop Everything
```powershell
docker-compose down
```

---

## 📖 Documentación
- Más info: [INDEX.md](INDEX.md)
- Quick start completo: [QUICK_START.md](QUICK_START.md)
- Presentación: [PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md)
