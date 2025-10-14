#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Iniciando validación completa de servicios Kafka...${NC}"

# Ejecutar todas las validaciones
./scripts/validate-zookeeper.sh
echo ""
./scripts/validate-kafka.sh
echo ""
./scripts/validate-kafka-ui.sh

echo ""
echo -e "${CYAN}Resumen de servicios:${NC}"
echo -e "- ${BLUE}Zookeeper:${NC} localhost:2181"
echo -e "- ${BLUE}Kafka:${NC} localhost:9092 (externo), localhost:29092 (interno)"
echo -e "- ${BLUE}Kafka UI:${NC} http://localhost:8080"