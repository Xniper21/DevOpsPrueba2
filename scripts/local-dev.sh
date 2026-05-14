#!/bin/bash

# =====================================================
# Docker Local Development Environment Setup
# Usage: ./scripts/local-dev.sh [command]
# Commands: up, down, restart, logs, clean
# =====================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
COMMAND="${1:-up}"

# Functions
print_header() {
    echo -e "${BLUE}======================================"
    echo -e "$1"
    echo -e "======================================${NC}"
}

print_step() {
    echo -e "${YELLOW}➜ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ===== Commands =====
case "${COMMAND}" in
    up)
        print_header "Starting Development Environment"
        print_step "Building and starting containers..."
        docker-compose up -d
        print_success "Containers started successfully"
        
        echo ""
        echo -e "${BLUE}Services running:${NC}"
        echo -e "  • MySQL:       ${YELLOW}localhost:3306${NC}"
        echo -e "  • Ventas API:  ${YELLOW}http://localhost:8080${NC}"
        echo -e "  • Despacho API: ${YELLOW}http://localhost:8081${NC}"
        echo -e "  • Frontend:    ${YELLOW}http://localhost${NC}"
        
        print_step "Waiting for services to be healthy..."
        sleep 10
        
        if curl -s http://localhost/health >/dev/null; then
            print_success "All services are healthy!"
        else
            print_error "Some services may not be ready yet"
        fi
        ;;
    
    down)
        print_header "Stopping Development Environment"
        print_step "Stopping containers..."
        docker-compose down
        print_success "Containers stopped"
        ;;
    
    restart)
        print_header "Restarting Development Environment"
        print_step "Restarting containers..."
        docker-compose restart
        print_success "Containers restarted"
        ;;
    
    logs)
        print_header "Viewing Logs"
        service="${2:-}"
        if [ -n "${service}" ]; then
            echo -e "${YELLOW}Logs for: ${service}${NC}"
            docker-compose logs -f "${service}"
        else
            echo -e "${YELLOW}Available services:${NC}"
            docker-compose logs --services
            echo ""
            echo "Usage: ./scripts/local-dev.sh logs [service]"
        fi
        ;;
    
    clean)
        print_header "Cleaning Development Environment"
        print_step "Stopping containers..."
        docker-compose down
        
        print_step "Removing volumes..."
        docker volume rm innovatechdb_mysql_data 2>/dev/null || true
        
        print_step "Pruning unused Docker resources..."
        docker system prune -f
        
        print_success "Cleanup complete"
        ;;
    
    shell)
        service="${2:-mysql}"
        print_step "Opening shell in ${service} container..."
        docker-compose exec "${service}" sh
        ;;
    
    ps)
        print_header "Container Status"
        docker-compose ps
        ;;
    
    *)
        echo "Usage: ./scripts/local-dev.sh [command]"
        echo ""
        echo "Commands:"
        echo "  up       - Start development environment"
        echo "  down     - Stop development environment"
        echo "  restart  - Restart containers"
        echo "  logs     - View logs (optionally specify service)"
        echo "  shell    - Open shell in container (optionally specify service)"
        echo "  ps       - Show container status"
        echo "  clean    - Stop and cleanup volumes"
        exit 1
        ;;
esac
