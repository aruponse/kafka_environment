#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Validando Kafka UI...${NC}"

# Verificar si el contenedor está ejecutándose
if docker ps | grep -q "kafka-ui"; then
    echo -e "${GREEN}Contenedor kafka-ui está ejecutándose${NC}"
else
    echo -e "${RED}Contenedor kafka-ui NO está ejecutándose${NC}"
    exit 1
fi

# Verificar puerto 8080
echo -e "${BLUE}Verificando conectividad en puerto 8080...${NC}"
if nc -z localhost 8080; then
    echo -e "${GREEN}Puerto 8080 accesible${NC}"
else
    echo -e "${RED}Puerto 8080 NO accesible${NC}"
    exit 1
fi

# Verificar respuesta HTTP
echo -e "${BLUE}Verificando respuesta HTTP...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo -e "${GREEN}Kafka UI responde correctamente${NC}"
    echo -e "${CYAN}Accede a Kafka UI en: http://localhost:8080${NC}"
else
    echo -e "${YELLOW}Kafka UI puede estar iniciándose, verifica en http://localhost:8080${NC}"
fi

# Verificar logs
echo -e "${BLUE}Verificando logs de Kafka UI...${NC}"
if docker logs kafka-ui 2>&1 | grep -q -E "(Started|Tomcat started)"; then
    echo -e "${GREEN}Kafka UI se inició correctamente${NC}"
else
    echo -e "${YELLOW}Revisar logs de Kafka UI${NC}"
    docker logs kafka-ui --tail 5
fi

echo -e "${GREEN}Validación de Kafka UI completada${NC}"