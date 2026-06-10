# Neo4j Movie Graph CSV Only

Este proyecto contiene solamente una instancia local de Neo4j y los archivos CSV del grafo de películas y series.

No incluye backend, frontend ni script de carga automática. La base de datos inicia vacía; los CSV quedan montados dentro del contenedor para que puedas importarlos manualmente desde Neo4j.

## Iniciar Neo4j

Desde esta carpeta:

```bash
docker compose up
```

## Neo4j Browser

Abre Neo4j Browser en:

```text
http://localhost:7474
```

Credenciales:

```text
usuario: neo4j
contraseña: password123
```

Bolt está disponible en:

```text
bolt://localhost:7687
```

## CSV

Los CSV están en:

```text
data/csv/
```

## Persistencia

Los datos de Neo4j se guardan en volúmenes Docker. Esto conserva la base de datos cuando detienes o reinicias el contenedor:

```bash
docker compose down
```

Solo este comando borra los volúmenes y los datos de Neo4j:

```bash
docker compose down -v
```

