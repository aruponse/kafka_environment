# Kafka Docker Environment

Entorno de desarrollo con Apache Kafka (Confluent Platform 7.4), Zookeeper y Kafka UI mediante Docker Compose. Incluye scripts para configuración, validación y gestión de topics.

Los datos persistentes viven **fuera** del directorio `kafka/`, en la carpeta compartida del repositorio Docker: `Volumes/kafka/`. El `docker-compose.yml` monta esas rutas con bind mounts (`../Volumes/kafka/...`).

## Arquitectura del proyecto

Vista respecto al repositorio **Docker** (padre de `kafka/`):

```
Docker/
├── Volumes/kafka/                 # Datos persistentes (bind mounts)
│   ├── kafka-data/                # Datos del broker → /var/lib/kafka/data
│   ├── kafka-logs/                # Logs del broker → /opt/kafka/logs
│   ├── zookeeper-data/            # Datos de Zookeeper → /var/lib/zookeeper/data
│   └── zookeeper-logs/            # Logs de Zookeeper → /var/lib/zookeeper/log
└── kafka/
    ├── docker-compose.yml         # Servicios, red kafka-net, límites y JVM
    ├── .env.kafka                 # Variables del broker (listeners, topics, etc.)
    ├── .env.zookeeper             # Variables de Zookeeper
    └── scripts/                   # Automatización
        ├── setup-all.sh
        ├── validate-all.sh
        ├── manage-topics.sh
        ├── validate-kafka.sh
        ├── validate-zookeeper.sh
        ├── validate-kafka-ui.sh
        ├── configure-kafka.sh     # Crea .env y directorios bajo Volumes/kafka
        └── configure-zookeeper.sh
```

**Red Docker**: todos los servicios usan la red bridge explícita `kafka-net` (nombre `kafka-net`). Kafka UI contacta al broker en `kafka:29092` (listener interno).

## Recursos y optimización (JVM)

Los límites y heaps siguen la tabla **`recommended_settings.md`** en la raíz del repo Docker (valores orientativos para desarrollo local).

| Servicio   | CPU (límite) | RAM (límite) | Ajuste JVM / notas                                      |
|------------|--------------|--------------|---------------------------------------------------------|
| Zookeeper  | 0.2          | 256 MB       | `KAFKA_HEAP_OPTS`: -Xmx128m -Xms128m                    |
| Kafka      | 0.5          | 768 MB       | `KAFKA_HEAP_OPTS`: -Xmx512m -Xms512m                      |
| Kafka UI   | 0.1          | 256 MB       | `JAVA_OPTS`: -Xms64m -Xmx192m                           |

`deploy.resources` en Compose aplica con **Docker Compose v2** (`docker compose up`). `shm_size` no se define en este stack (a diferencia de otros servicios del repo); Zookeeper/Kafka usan la JVM acotada como principal palanca de memoria.

## Inicio rápido

Ejecuta los comandos desde el directorio **`kafka/`**.

### 1. Setup inicial automático

```bash
./scripts/setup-all.sh
```

Este flujo suele: crear `.env` si faltan, crear directorios bajo `Docker/Volumes/kafka/`, levantar servicios y validar.

### 2. Inicio manual

```bash
docker compose up -d
./scripts/validate-all.sh
```

Se recomienda el plugin **Compose v2** (`docker compose`). Si aún usas el binario legado, sustituye por `docker-compose` donde aplique.

## Servicios incluidos

| Servicio    | Puerto | Descripción |
|-------------|--------|-------------|
| Zookeeper   | 2181   | Coordinación; healthcheck en 2181                       |
| Kafka       | 9092 (externo), 29092 (interno) | Broker |
| Kafka UI    | 8080   | Consola web (cluster `local-kafka` → `kafka:29092`)     |

### Acceso

- **Kafka UI**: http://localhost:8080
- **Kafka (clientes en el host)**: `localhost:9092`
- **Zookeeper**: `localhost:2181`

## Scripts de gestión

### `manage-topics.sh`

```bash
./scripts/manage-topics.sh list
./scripts/manage-topics.sh create mi-topic 3 1
./scripts/manage-topics.sh describe mi-topic
./scripts/manage-topics.sh clean mi-topic
./scripts/manage-topics.sh clean-all
./scripts/manage-topics.sh demo
./scripts/manage-topics.sh validate
```

### Validación

```bash
./scripts/validate-all.sh
./scripts/validate-kafka.sh
./scripts/validate-zookeeper.sh
./scripts/validate-kafka-ui.sh
```

### Configuración (env + carpetas en `Volumes/kafka`)

```bash
./scripts/configure-kafka.sh
./scripts/configure-zookeeper.sh
```

Los scripts resuelven la ruta al repo Docker y crean `Volumes/kafka/{kafka-data,kafka-logs,zookeeper-data,zookeeper-logs}` si no existen.

## Comandos Docker útiles

```bash
docker compose logs kafka
docker compose logs zookeeper
docker compose logs kafka-ui

docker compose restart
docker compose down
```

**Borrar datos del broker / Zookeeper**: el proyecto **no** usa volúmenes nombrados de Compose para los datos; usa **bind mounts** en `Docker/Volumes/kafka/`. `docker compose down -v` no elimina esas carpetas. Para un reset completo hay que parar los contenedores y borrar o vaciar manualmente el contenido de `Volumes/kafka/` (operación destructiva; haz copia previa si necesitas los topics).

## Configuración avanzada

### Listeners (dual)

- **9092**: clientes en el host (`EXTERNAL` en `.env.kafka`).
- **29092**: clientes dentro de Docker (`INTERNAL`; p. ej. Kafka UI usa `kafka:29092`).

### Variables de entorno

**Kafka (`.env.kafka`)** — ejemplo:

```bash
KAFKA_BROKER_ID=1
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
KAFKA_LISTENERS=INTERNAL://0.0.0.0:29092,EXTERNAL://0.0.0.0:9092
KAFKA_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://localhost:9092
```

Los heaps del broker y de Zookeeper se fijan en **`docker-compose.yml`** (`environment`), no en los `.env`, para mantenerlos alineados con los límites de memoria del contenedor.

**Zookeeper (`.env.zookeeper`)** — ejemplo:

```bash
ZOOKEEPER_CLIENT_PORT=2181
ZOOKEEPER_TICK_TIME=2000
```

## Uso con aplicaciones

### Clientes en el host

```bash
KAFKA_BROKERS=localhost:9092
```

### Ejemplos con el contenedor del broker

```bash
docker exec kafka-broker kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic mi-topic \
  --partitions 3 --replication-factor 1

echo "Hola Kafka" | docker exec -i kafka-broker \
  kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic mi-topic

docker exec kafka-broker kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mi-topic \
  --from-beginning
```

## Solución de problemas

### Kafka no conecta

```bash
docker ps
docker logs kafka-broker
./scripts/validate-kafka.sh
```

### Kafka UI muestra clusters offline

```bash
./scripts/validate-kafka-ui.sh
docker compose restart kafka-ui
```

Comprueba que el broker esté sano y que la UI apunte a `kafka:29092` (red `kafka-net`).

### Topics no persisten tras reinicio

```bash
ls -la ../Volumes/kafka/
./scripts/manage-topics.sh validate
```

Ruta absoluta típica: `<repo Docker>/Volumes/kafka/`.

## Monitoreo y logs

```bash
./scripts/validate-all.sh
docker compose logs -f
docker compose logs -f kafka
docker compose logs -f kafka-ui
```

En http://localhost:8080 puedes revisar topics, brokers y grupos de consumo.

## Desarrollo

```bash
./scripts/manage-topics.sh create user-events 5 1
./scripts/manage-topics.sh create order-processing 3 1
./scripts/manage-topics.sh create notifications 2 1
```

```bash
./scripts/manage-topics.sh clean-all
docker compose down
docker compose up -d
```

## Recursos adicionales

- [Documentación de Apache Kafka](https://kafka.apache.org/documentation/)
- [Kafka UI (GitHub)](https://github.com/provectus/kafka-ui)
- [Referencia Docker Compose](https://docs.docker.com/compose/)

## Contribución

1. Cambia scripts o configuración y prueba con `./scripts/validate-all.sh`.
2. Actualiza este README si cambia la arquitectura, rutas o límites de recursos.

---

Este entorno está pensado para **desarrollo local**. En producción revisa seguridad (TLS/SASL), replicación, particionamiento y recursos según carga real.
