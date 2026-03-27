#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Configurando Kafka...${NC}"

# Crear archivo .env.kafka si no existe
if [ ! -f .env.kafka ]; then
    echo -e "${BLUE}Creando archivo .env.kafka...${NC}"
    cat > .env.kafka << EOF
# Configuración de Kafka
TZ=America/Guayaquil
KAFKA_BROKER_ID=1
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
KAFKA_LISTENERS=INTERNAL://0.0.0.0:29092,EXTERNAL://0.0.0.0:9092
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL
KAFKA_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://localhost:9092
KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1
KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1
KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=100
KAFKA_NUM_PARTITIONS=3
CONFLUENT_METRICS_ENABLE=false
EOF
    echo -e "${GREEN}Archivo .env.kafka creado${NC}"
else
    echo -e "${GREEN}Archivo .env.kafka ya existe${NC}"
fi

# Crear directorios de datos y logs si no existen (Docker/Volumes/kafka)
DOCKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KAFKA_VOLUME_ROOT="${DOCKER_ROOT}/Volumes/kafka"
mkdir -p "${KAFKA_VOLUME_ROOT}/kafka-data" "${KAFKA_VOLUME_ROOT}/kafka-logs"
echo -e "${GREEN}Directorios de datos y logs creados en ${KAFKA_VOLUME_ROOT}${NC}"

echo -e "${GREEN}Configuración de Kafka completada${NC}"