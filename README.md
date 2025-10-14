# Kafka Docker Environment

Un entorno completo de desarrollo con Apache Kafka, Zookeeper y Kafka UI usando Docker Compose. Este proyecto incluye scripts automatizados para configuración, validación y gestión de topics.

## 🏗️ Arquitectura del Proyecto

```
kafka/
├── docker-compose.yml          # Configuración de servicios Docker
├── .env.kafka                  # Variables de entorno para Kafka
├── .env.zookeeper             # Variables de entorno para Zookeeper
├── volumes/                   # Datos persistentes
│   ├── kafka-data/           # Datos de Kafka
│   ├── kafka-logs/           # Logs de Kafka
│   ├── zookeeper-data/       # Datos de Zookeeper
│   └── zookeeper-logs/       # Logs de Zookeeper
└── scripts/                  # Scripts de automatización
    ├── setup-all.sh          # Configuración inicial completa
    ├── validate-all.sh       # Validación completa de servicios
    ├── manage-topics.sh      # Gestión de topics
    ├── validate-kafka.sh     # Validación específica de Kafka
    ├── validate-zookeeper.sh # Validación específica de Zookeeper
    ├── validate-kafka-ui.sh  # Validación específica de Kafka UI
    ├── configure-kafka.sh    # Configuración de Kafka
    └── configure-zookeeper.sh # Configuración de Zookeeper
```

## 🚀 Inicio Rápido

### 1. Setup Inicial Automático

```bash
# Configurar todo el entorno de una vez
./scripts/setup-all.sh
```

Este comando:
- Crea archivos de configuración (.env)
- Crea directorios de datos persistentes
- Levanta todos los servicios
- Valida que todo esté funcionando

### 2. Inicio Manual

```bash
# Solo levantar los servicios
docker-compose up -d

# Validar que todo funcione
./scripts/validate-all.sh
```

## 🔧 Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **Zookeeper** | 2181 | Coordinación y configuración distribuida |
| **Kafka** | 9092 (externo)<br>29092 (interno) | Broker de mensajería |
| **Kafka UI** | 8080 | Interfaz web para administración |

### Acceso a los Servicios

- **Kafka UI**: http://localhost:8080
- **Kafka (clientes externos)**: localhost:9092
- **Zookeeper**: localhost:2181

## 📝 Scripts de Gestión

### `manage-topics.sh` - Gestión de Topics

```bash
# Listar todos los topics
./scripts/manage-topics.sh list

# Crear un topic
./scripts/manage-topics.sh create mi-topic 3 1
#                                    ↑     ↑ ↑
#                                 nombre  particiones replicación

# Describir un topic específico
./scripts/manage-topics.sh describe mi-topic

# Limpiar eventos de un topic (elimina todos los mensajes)
./scripts/manage-topics.sh clean mi-topic

# Limpiar TODOS los topics de usuario (¡CUIDADO!)
./scripts/manage-topics.sh clean-all

# Crear topics de demostración
./scripts/manage-topics.sh demo

# Validar persistencia de topics
./scripts/manage-topics.sh validate
```

### Scripts de Validación

```bash
# Validación completa de todos los servicios
./scripts/validate-all.sh

# Validaciones individuales
./scripts/validate-kafka.sh
./scripts/validate-zookeeper.sh
./scripts/validate-kafka-ui.sh
```

### Scripts de Configuración

```bash
# Configurar Kafka
./scripts/configure-kafka.sh

# Configurar Zookeeper
./scripts/configure-zookeeper.sh
```

## 🐳 Comandos Docker Útiles

```bash
# Ver logs de los servicios
docker-compose logs kafka
docker-compose logs zookeeper
docker-compose logs kafka-ui

# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Detener y eliminar datos (¡CUIDADO!)
docker-compose down -v
```

## 🔧 Configuración Avanzada

### Configuración de Red

El proyecto usa una configuración de red dual para Kafka:

- **Puerto 9092**: Para clientes externos (aplicaciones desde el host)
- **Puerto 29092**: Para comunicación interna entre contenedores

### Persistencia de Datos

Los datos se almacenan en volúmenes Docker mapeados a directorios locales:
- Kafka: `./volumes/kafka-data/` y `./volumes/kafka-logs/`
- Zookeeper: `./volumes/zookeeper-data/` y `./volumes/zookeeper-logs/`

### Variables de Entorno

**Kafka (`.env.kafka`)**:
```bash
KAFKA_BROKER_ID=1
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
KAFKA_LISTENERS=INTERNAL://0.0.0.0:29092,EXTERNAL://0.0.0.0:9092
KAFKA_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://localhost:9092
```

**Zookeeper (`.env.zookeeper`)**:
```bash
ZOOKEEPER_CLIENT_PORT=2181
ZOOKEEPER_TICK_TIME=2000
```

## 📊 Uso con Aplicaciones

### Conectar desde Aplicaciones Externas

```bash
# Configuración para clientes externos
KAFKA_BROKERS=localhost:9092
```

### Ejemplos de Comandos de Cliente

```bash
# Crear un topic manualmente
docker exec kafka-broker kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic mi-topic \
  --partitions 3 --replication-factor 1

# Enviar mensajes
echo "Hola Kafka" | docker exec -i kafka-broker \
  kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic mi-topic

# Consumir mensajes
docker exec kafka-broker kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mi-topic \
  --from-beginning
```

## 🚨 Solución de Problemas

### Kafka no se conecta
```bash
# Verificar estado de contenedores
docker ps

# Ver logs de Kafka
docker logs kafka-broker

# Validar configuración
./scripts/validate-kafka.sh
```

### Kafka UI muestra "Offline Clusters"
```bash
# Verificar conectividad de red
./scripts/validate-kafka-ui.sh

# Reiniciar Kafka UI
docker-compose restart kafka-ui
```

### Topics no persisten después de reinicio
```bash
# Verificar volúmenes
ls -la volumes/

# Validar persistencia
./scripts/manage-topics.sh validate
```

## 🔍 Monitoreo y Logs

### Verificar Estado General
```bash
./scripts/validate-all.sh
```

### Logs en Tiempo Real
```bash
# Todos los servicios
docker-compose logs -f

# Solo Kafka
docker-compose logs -f kafka

# Solo Kafka UI
docker-compose logs -f kafka-ui
```

### Métricas en Kafka UI

Accede a http://localhost:8080 para ver:
- Estado de topics y particiones
- Mensajes en tiempo real
- Configuración de brokers
- Grupos de consumidores

## 🛠️ Desarrollo

### Agregar Nuevos Topics de Desarrollo

```bash
# Crear topics comunes para desarrollo
./scripts/manage-topics.sh create user-events 5 1
./scripts/manage-topics.sh create order-processing 3 1
./scripts/manage-topics.sh create notifications 2 1
```

### Limpiar Entorno de Desarrollo

```bash
# Limpiar todos los topics manteniendo la estructura
./scripts/manage-topics.sh clean-all

# O reiniciar completamente
docker-compose down
docker-compose up -d
```

## 📚 Recursos Adicionales

- [Documentación oficial de Kafka](https://kafka.apache.org/documentation/)
- [Kafka UI GitHub](https://github.com/provectus/kafka-ui)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contribución

Para contribuir al proyecto:

1. Haz cambios en los scripts o configuración
2. Prueba con `./scripts/validate-all.sh`
3. Documenta los cambios en este README
4. Asegúrate de que todos los scripts funcionen correctamente

---

**Nota**: Este entorno está optimizado para desarrollo local. Para producción, considera ajustar la configuración de seguridad, replicación y recursos.