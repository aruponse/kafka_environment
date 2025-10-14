#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Configurando entorno Kafka completo...${NC}"

# Ejecutar configuraciones
./scripts/configure-zookeeper.sh
echo ""
./scripts/configure-kafka.sh

# Hacer ejecutables todos los scripts
chmod +x scripts/*.sh
echo -e "${GREEN}Scripts hechos ejecutables${NC}"

# Levantar servicios
echo ""
echo -e "${BLUE}Iniciando servicios Docker...${NC}"
docker-compose up -d

echo ""
echo -e "${YELLOW}Esperando que los servicios se inicien...${NC}"
sleep 15

echo ""
echo -e "${BLUE}Validando servicios...${NC}"
./scripts/validate-all.sh

echo ""
echo -e "${GREEN}Setup completo finalizado!${NC}"