#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Validando Kafka...${NC}"

# Verificar si el contenedor está ejecutándose
if docker ps | grep -q "kafka-broker"; then
    echo -e "${GREEN}Contenedor kafka-broker está ejecutándose${NC}"
else
    echo -e "${RED}Contenedor kafka-broker NO está ejecutándose${NC}"
    exit 1
fi

# Verificar puertos de Kafka
echo -e "${BLUE}Verificando conectividad de puertos...${NC}"
if nc -z localhost 9092; then
    echo -e "${GREEN}Puerto 9092 (externo) accesible${NC}"
else
    echo -e "${RED}Puerto 9092 (externo) NO accesible${NC}"
fi

if nc -z localhost 29092; then
    echo -e "${GREEN}Puerto 29092 (interno) accesible${NC}"
else
    echo -e "${RED}Puerto 29092 (interno) NO accesible${NC}"
fi

# Verificar logs de Kafka
echo -e "${BLUE}Verificando logs de Kafka...${NC}"
if docker logs kafka-broker 2>&1 | grep -q "started (kafka.server.KafkaServer)"; then
    echo -e "${GREEN}Kafka se inició correctamente${NC}"
else
    echo -e "${YELLOW}Revisar logs de Kafka${NC}"
    docker logs kafka-broker --tail 10
fi

# Validar capacidad de crear topics
echo -e "${BLUE}Validando capacidad de crear topics...${NC}"
TEMP_TOPIC="temp-validation-$(date +%s)"
if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --create --topic "$TEMP_TOPIC" --partitions 1 --replication-factor 1 2>/dev/null; then
    echo -e "${GREEN}Capacidad de crear topics validada${NC}"
    
    # Listar topics existentes
    echo -e "${CYAN}Listando todos los topics...${NC}"
    docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list
    
    # Limpiar - eliminar solo el topic temporal
    docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --delete --topic "$TEMP_TOPIC" 2>/dev/null
    echo -e "${YELLOW}Topic temporal eliminado${NC}"
else
    echo -e "${RED}No se pudo validar la creación de topics${NC}"
fi

echo -e "${GREEN}Validación de Kafka completada${NC}"