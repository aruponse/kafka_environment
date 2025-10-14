#!/bin/bash

# Colores para el output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Gestión de Topics de Kafka...${NC}"

# Función para crear un topic
create_topic() {
    local topic_name=$1
    local partitions=${2:-3}
    local replication_factor=${3:-1}
    
    echo -e "${BLUE}Creando topic: $topic_name${NC}"
    if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --create --topic "$topic_name" --partitions "$partitions" --replication-factor "$replication_factor" 2>/dev/null; then
        echo -e "${GREEN}Topic '$topic_name' creado exitosamente${NC}"
        return 0
    else
        echo -e "${YELLOW}Topic '$topic_name' ya existe o hubo un error${NC}"
        return 1
    fi
}

# Función para listar topics
list_topics() {
    echo -e "${CYAN}Topics existentes:${NC}"
    docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list
}

# Función para describir un topic
describe_topic() {
    local topic_name=$1
    echo -e "${CYAN}Detalles del topic '$topic_name':${NC}"
    docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --describe --topic "$topic_name"
}

# Función para limpiar eventos de un topic específico
clean_topic() {
    local topic_name=$1
    
    if [ -z "$topic_name" ]; then
        echo -e "${RED}Error: Debes proporcionar un nombre de topic${NC}"
        return 1
    fi
    
    # Verificar si el topic existe
    if ! docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -q "^$topic_name$"; then
        echo -e "${RED}El topic '$topic_name' no existe${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Limpiando eventos del topic '$topic_name'...${NC}"
    echo -e "${RED}ADVERTENCIA: Esta operación eliminará TODOS los mensajes del topic recreándolo${NC}"
    read -p "¿Estás seguro? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Obteniendo configuración actual del topic...${NC}"
        
        # Obtener configuración actual del topic
        local config=$(docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --describe --topic "$topic_name" 2>/dev/null | head -n 1)
        if [ -z "$config" ]; then
            echo -e "${RED}No se pudo obtener la configuración del topic${NC}"
            return 1
        fi
        
        local partitions=$(echo "$config" | grep -o "PartitionCount: [0-9]*" | cut -d' ' -f2)
        local replication_factor=$(echo "$config" | grep -o "ReplicationFactor: [0-9]*" | cut -d' ' -f2)
        
        echo -e "  - Particiones: ${CYAN}$partitions${NC}"
        echo -e "  - Factor de replicación: ${CYAN}$replication_factor${NC}"
        
        # Eliminar el topic
        echo -e "${YELLOW}Eliminando topic '$topic_name'...${NC}"
        if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --delete --topic "$topic_name" 2>/dev/null; then
            echo -e "${GREEN}Topic eliminado${NC}"
        else
            echo -e "${RED}Error al eliminar el topic${NC}"
            return 1
        fi
        
        # Esperar a que se complete la eliminación
        echo -e "${BLUE}Esperando eliminación completa...${NC}"
        local attempts=0
        while docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -q "^$topic_name$" && [ $attempts -lt 10 ]; do
            sleep 1
            ((attempts++))
        done
        
        if [ $attempts -eq 10 ]; then
            echo -e "${YELLOW}El topic aún existe después de 10 segundos, continuando...${NC}"
        fi
        
        # Recrear el topic con la misma configuración
        echo -e "${BLUE}Recreando topic '$topic_name'...${NC}"
        if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --create --topic "$topic_name" --partitions "$partitions" --replication-factor "$replication_factor" 2>/dev/null; then
            echo -e "${GREEN}Topic '$topic_name' recreado exitosamente sin eventos${NC}"
            
            # Verificar que el topic existe y está vacío
            echo -e "${BLUE}Verificando que el topic esté vacío...${NC}"
            local message_count=$(timeout 3 docker exec kafka-broker kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic "$topic_name" --time -1 2>/dev/null | awk -F: '{sum+=$3} END {print sum+0}')
            
            if [ "$message_count" -eq 0 ]; then
                echo -e "${GREEN}Confirmado: El topic '$topic_name' está vacío (0 mensajes)${NC}"
            else
                echo -e "${YELLOW}El topic tiene $message_count mensajes (puede tomar tiempo en actualizarse)${NC}"
            fi
        else
            echo -e "${RED}Error al recrear el topic '$topic_name'${NC}"
            return 1
        fi
    else
        echo -e "${RED}Operación cancelada${NC}"
        return 1
    fi
}

# Función para limpiar eventos de todos los topics de usuario
clean_all_topics() {
    echo -e "${RED}Limpiando eventos de TODOS los topics de usuario...${NC}"
    echo -e "${RED}ADVERTENCIA: Esta operación eliminará TODOS los mensajes de TODOS los topics (excepto __consumer_offsets)${NC}"
    read -p "¿Estás COMPLETAMENTE seguro? Escribe 'CONFIRMAR' para continuar: " confirm
    
    if [[ $confirm == "CONFIRMAR" ]]; then
        # Obtener lista de topics de usuario (excluyendo los del sistema)
        local user_topics=$(docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -v "^__")
        
        if [ -z "$user_topics" ]; then
            echo -e "${BLUE}No hay topics de usuario para limpiar${NC}"
            return 0
        fi
        
        echo -e "${CYAN}Topics que serán limpiados:${NC}"
        echo "$user_topics"
        echo ""
        
        local cleaned_count=0
        local total_count=$(echo "$user_topics" | wc -l | tr -d ' ')
        
        while IFS= read -r topic; do
            if [ ! -z "$topic" ]; then
                echo -e "${YELLOW}Limpiando topic: $topic...${NC}"
                
                # Obtener configuración del topic
                local config=$(docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --describe --topic "$topic" | head -n 1)
                local partitions=$(echo "$config" | grep -o "PartitionCount: [0-9]*" | cut -d' ' -f2)
                local replication_factor=$(echo "$config" | grep -o "ReplicationFactor: [0-9]*" | cut -d' ' -f2)
                
                # Eliminar y recrear el topic
                docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --delete --topic "$topic" 2>/dev/null
                sleep 1
                
                if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --create --topic "$topic" --partitions "$partitions" --replication-factor "$replication_factor" 2>/dev/null; then
                    echo -e "  ${GREEN}Topic '$topic' limpiado${NC}"
                    ((cleaned_count++))
                else
                    echo -e "  ${RED}Error al limpiar topic '$topic'${NC}"
                fi
            fi
        done <<< "$user_topics"
        
        echo ""
        echo -e "${GREEN}Limpieza completada: $cleaned_count/$total_count topics procesados${NC}"
    else
        echo -e "${RED}Operación cancelada${NC}"
        return 1
    fi
}

# Función para validar persistencia de topics
validate_persistence() {
    echo -e "${BLUE}Validando persistencia de topics...${NC}"
    
    local topics_before=$(docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -v "^__" | wc -l | tr -d ' ')
    echo -e "${CYAN}Topics antes del reinicio: $topics_before${NC}"
    
    if [ "$topics_before" -gt 0 ]; then
        echo -e "${GREEN}Hay topics para validar persistencia${NC}"
        echo -e "${CYAN}Topics actuales:${NC}"
        docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -v "^__"
    else
        echo -e "${YELLOW}No hay topics de usuario para validar persistencia${NC}"
    fi
}

# Script principal
case "${1:-list}" in
    "create")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Debes proporcionar un nombre para el topic${NC}"
            echo "Uso: $0 create <topic-name> [partitions] [replication-factor]"
            exit 1
        fi
        create_topic "$2" "$3" "$4"
        ;;
    "list")
        list_topics
        ;;
    "describe")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Debes proporcionar un nombre de topic${NC}"
            echo "Uso: $0 describe <topic-name>"
            exit 1
        fi
        describe_topic "$2"
        ;;
    "clean")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Debes proporcionar un nombre de topic${NC}"
            echo "Uso: $0 clean <topic-name>"
            exit 1
        fi
        clean_topic "$2"
        ;;
    "clean-all")
        clean_all_topics
        ;;
    "validate")
        validate_persistence
        ;;
    "demo")
        echo -e "${BLUE}Creando topics de demostración...${NC}"
        create_topic "user-events" 3 1
        create_topic "order-processing" 5 1
        create_topic "notifications" 2 1
        echo ""
        list_topics
        ;;
    *)
        echo -e "${CYAN}Uso: $0 {create|list|describe|clean|clean-all|validate|demo}${NC}"
        echo ""
        echo -e "${BLUE}Comandos disponibles:${NC}"
        echo -e "  ${GREEN}list${NC}                          - Listar todos los topics"
        echo -e "  ${GREEN}create${NC} <name> [part] [rep]    - Crear un topic"
        echo -e "  ${GREEN}describe${NC} <name>               - Describir un topic específico"
        echo -e "  ${GREEN}clean${NC} <name>                  - Limpiar eventos de un topic específico"
        echo -e "  ${GREEN}clean-all${NC}                     - Limpiar eventos de TODOS los topics de usuario"
        echo -e "  ${GREEN}validate${NC}                      - Validar persistencia de topics"
        echo -e "  ${GREEN}demo${NC}                          - Crear topics de demostración"
        echo ""
        echo -e "${BLUE}Ejemplos:${NC}"
        echo "  $0 create my-topic 3 1"
        echo "  $0 describe my-topic"
        echo "  $0 clean my-topic"
        echo "  $0 clean-all"
        echo "  $0 demo"
        ;;
esac