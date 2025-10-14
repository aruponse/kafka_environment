#!/bin/bash

echo "📝 Creando y validando tópicos en Kafka..."

TOPIC_NAME=${1:-"demo-topic"}
PARTITIONS=${2:-3}
REPLICATION_FACTOR=${3:-1}

echo "🔧 Configuración del tópico:"
echo "  - Nombre: $TOPIC_NAME"
echo "  - Particiones: $PARTITIONS"
echo "  - Factor de replicación: $REPLICATION_FACTOR"

# Verificar si Kafka está corriendo
if ! docker ps | grep -q "kafka-broker"; then
    echo "❌ Kafka no está corriendo. Inicia los servicios primero."
    exit 1
fi

# Verificar si el tópico ya existe
echo "🔍 Verificando si el tópico '$TOPIC_NAME' ya existe..."
if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list | grep -q "^$TOPIC_NAME$"; then
    echo "ℹ️  El tópico '$TOPIC_NAME' ya existe"
else
    # Crear el tópico
    echo "➕ Creando tópico '$TOPIC_NAME'..."
    if docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --create --topic "$TOPIC_NAME" --partitions "$PARTITIONS" --replication-factor "$REPLICATION_FACTOR"; then
        echo "✅ Tópico '$TOPIC_NAME' creado exitosamente"
    else
        echo "❌ Error al crear el tópico '$TOPIC_NAME'"
        exit 1
    fi
fi

# Validar detalles del tópico
echo "📋 Validando detalles del tópico '$TOPIC_NAME'..."
docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --describe --topic "$TOPIC_NAME"

# Listar todos los tópicos
echo ""
echo "📝 Lista de todos los tópicos:"
docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list

# Probar envío y recepción de mensajes
echo ""
echo "🧪 Probando envío de mensaje de prueba..."
echo "test-message-$(date +%s)" | docker exec -i kafka-broker kafka-console-producer --bootstrap-server localhost:9092 --topic "$TOPIC_NAME"

echo ""
echo "📨 Leyendo mensajes del tópico (últimos 5 segundos)..."
timeout 5 docker exec kafka-broker kafka-console-consumer --bootstrap-server localhost:9092 --topic "$TOPIC_NAME" --from-beginning --timeout-ms 3000 2>/dev/null || echo "ℹ️  Timeout alcanzado (comportamiento esperado)"

echo ""
echo "✨ Validación del tópico '$TOPIC_NAME' completada"
echo "🎯 El tópico '$TOPIC_NAME' está listo para usar en localhost:9092"