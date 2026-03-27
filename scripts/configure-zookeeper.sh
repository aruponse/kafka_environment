#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Configurando Zookeeper...${NC}"

# Crear archivo .env.zookeeper si no existe
if [ ! -f .env.zookeeper ]; then
    echo -e "${BLUE}Creando archivo .env.zookeeper...${NC}"
    cat > .env.zookeeper << EOF
# Configuración de Zookeeper
ZOOKEEPER_CLIENT_PORT=2181
ZOOKEEPER_TICK_TIME=2000
ZOOKEEPER_INIT_LIMIT=10
ZOOKEEPER_SYNC_LIMIT=5
ZOOKEEPER_MAX_CLIENT_CNXNS=60
ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT=3
ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL=24
EOF
    echo -e "${GREEN}Archivo .env.zookeeper creado${NC}"
else
    echo -e "${GREEN}Archivo .env.zookeeper ya existe${NC}"
fi

# Crear directorios de datos y logs si no existen (Docker/Volumes/kafka)
DOCKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KAFKA_VOLUME_ROOT="${DOCKER_ROOT}/Volumes/kafka"
mkdir -p "${KAFKA_VOLUME_ROOT}/zookeeper-data" "${KAFKA_VOLUME_ROOT}/zookeeper-logs"
echo -e "${GREEN}Directorios de Zookeeper creados en ${KAFKA_VOLUME_ROOT}${NC}"

echo -e "${GREEN}Configuración de Zookeeper completada${NC}"