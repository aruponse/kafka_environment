#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Validando Zookeeper...${NC}"

# Verificar si el contenedor está ejecutándose
if docker ps | grep -q "kafka-zookeeper"; then
    echo -e "${GREEN}Contenedor kafka-zookeeper está ejecutándose${NC}"
else
    echo -e "${RED}Contenedor kafka-zookeeper NO está ejecutándose${NC}"
    exit 1
fi

# Verificar conectividad del puerto 2181
echo -e "${BLUE}Verificando conectividad en puerto 2181...${NC}"
if nc -z localhost 2181; then
    echo -e "${GREEN}Puerto 2181 accesible${NC}"
else
    echo -e "${RED}Puerto 2181 NO accesible${NC}"
    exit 1
fi

# Verificar logs de Zookeeper
echo -e "${BLUE}Verificando logs de Zookeeper...${NC}"
if docker logs kafka-zookeeper 2>&1 | grep -q "binding to port"; then
    echo -e "${GREEN}Zookeeper se inició correctamente${NC}"
else
    echo -e "${YELLOW}Revisar logs de Zookeeper${NC}"
    docker logs kafka-zookeeper --tail 10
fi

# Test de comando Zookeeper
echo -e "${BLUE}Probando comando de Zookeeper...${NC}"
if docker exec kafka-zookeeper zkServer.sh status 2>/dev/null | grep -q "Mode:"; then
    echo -e "${GREEN}Zookeeper responde a comandos${NC}"
else
    echo -e "${RED}Zookeeper NO responde a comandos${NC}"
fi

echo -e "${GREEN}Validación de Zookeeper completada${NC}"