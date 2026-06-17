# Guía de recreación — Lab 05 Neo4j (Base de Datos III, ING0250, UM)

Este documento describe paso a paso cómo se construyó el proyecto con asistencia de IA (Claude Code),
de forma que pueda ser recreado siguiendo la misma secuencia de prompts y decisiones.

---

## Paso 1: Contexto inicial

Se le entregó a Claude el PDF del enunciado (`ING0250 - Lab05 - Neo4j.pdf`) junto con el siguiente contexto:

> "Tengo un template de Neo4j con Docker y 19 CSVs de datos de cine/TV. Hay dos tipos de archivos:
> los que representan entidades (que van a ser nodos) y los que representan conexiones (que van a ser relaciones).
>
> **Nodos:** Character, Company, Episode, Genre, Movie, Person, Season, Series
>
> **Relaciones:** ACTED_IN, APPEARS_IN, CREATED, DIRECTED, HAS_EPISODE, HAS_GENRE, HAS_SEASON,
> PLAYED, PRODUCED, PRODUCED_BY, WROTE
>
> Primero creá todos los nodos y después, con los archivos de cruce, creá las relaciones."

Antes de generar cualquier código, se le pidió que mostrara de qué CSV iba a sacar cada relación,
para verificar que el mapeo fuera correcto. Claude presentó el plan completo y fue aprobado sin correcciones.

---

## Paso 2: Orden de ejecución

Se le preguntó a Claude cuál era el orden correcto para construir el grafo. Respondió:

1. **Constraints** — garantizar unicidad de nodos antes de cargar datos
2. **Nodos** — cargar las 8 entidades desde los CSVs
3. **Relaciones** — crear las conexiones entre nodos ya existentes
4. **Consultas** — una vez validado que el grafo estaba bien cargado

Se siguió ese orden durante todo el desarrollo.

---

## Paso 3: Generación de los scripts Cypher

Con el plan aprobado, se le pidió a Claude que generara los scripts en ese orden:

### 3.1 `cypher/01_constraints.cypher`

> "Generá los constraints de unicidad para los 8 labels según sus IDs."

Resultado: un constraint `UNIQUE` por label sobre la propiedad `id`.

### 3.2 `cypher/02_load_nodes.cypher`

> "Generá el script de carga de nodos con LOAD CSV y MERGE para cada entidad."

Decisiones tomadas durante la generación:
- `toIntegerOrNull()` / `toFloatOrNull()` para campos numéricos (maneja celdas vacías sin romper la carga)
- `Person.primaryProfession` se guarda como lista usando `split(row.primaryProfession, '; ')`
- `Episode` y `Season` no guardan `seriesId`/`seasonId` como propiedades porque esas relaciones se modelan con `HAS_SEASON` y `HAS_EPISODE`

Resultado: **914 nodos** (Movie 30, Series 10, Season 30, Episode 120, Person 405, Character 188, Genre 86, Company 45).

### 3.3 `cypher/03_load_relationships.cypher`

> "Generá el script de carga de relaciones usando MATCH para encontrar los nodos ya existentes y MERGE para crear las relaciones."

Relaciones creadas y su CSV de origen:

| Relación | CSV origen | Patrón |
|---|---|---|
| `HAS_SEASON` | `seasons.csv` | `(Series)-[:HAS_SEASON]->(Season)` |
| `HAS_EPISODE` | `episodes.csv` | `(Season)-[:HAS_EPISODE]->(Episode)` |
| `HAS_GENRE` | `movie_genres.csv` / `series_genres.csv` | `(Movie\|Series)-[:HAS_GENRE]->(Genre)` |
| `PRODUCED_BY` | `production_companies.csv` | `(Movie\|Series)-[:PRODUCED_BY]->(Company)` |
| `DIRECTED` / `WROTE` / `PRODUCED` | `movie_directors.csv` / `movie_writers.csv` / `movie_producers.csv` | `(Person)-[:REL]->(Movie)` |
| `CREATED` | `series_creators.csv` | `(Person)-[:CREATED]->(Series)` |
| `DIRECTED` / `WROTE` | `episode_directors.csv` / `episode_writers.csv` | `(Person)-[:REL]->(Episode)` |
| `ACTED_IN` | `movie_cast.csv` / `episode_cast.csv` | `(Person)-[:ACTED_IN]->(Movie\|Episode)` |
| `PLAYED {role}` | `movie_cast.csv` / `episode_cast.csv` | `(Person)-[:PLAYED]->(Character)` |
| `APPEARS_IN` | `movie_cast.csv` / `episode_cast.csv` | `(Character)-[:APPEARS_IN]->(Movie\|Episode)` |

El triángulo `Person-PLAYED->Character-APPEARS_IN->(Movie|Episode)` permite resolver casos de
doble personaje en una misma obra y personajes interpretados por más de un actor.

Resultado: **2620 relaciones** (ACTED_IN 769, APPEARS_IN 729, WROTE 205, HAS_GENRE 237,
PLAYED 199, DIRECTED 163, PRODUCED_BY 83, PRODUCED 67, HAS_EPISODE 120, HAS_SEASON 30, CREATED 18).

Cada script se verificó en Neo4j Browser (`localhost:7474`) antes de continuar al siguiente.

---

## Paso 4: Consultas obligatorias (`cypher/04_consultas.cypher`, Q1–Q30)

Se le pasó a Claude el archivo `queries/consultas.md` con las 30 consultas predeterminadas
(25 obligatorias del PDF + 5 extra del enunciado) agrupadas por dificultad:

> "Resolvé estas 30 consultas en Cypher. El archivo tiene el enunciado de cada una."

Claude generó todas las consultas en un solo bloque. Se verificaron en Neo4j Browser y devolvieron
los resultados esperados sin necesidad de correcciones.

Algunos resultados destacados:
- **Q13 / Q25**: 14 actores interpretan más de un personaje (ej. Samuel L. Jackson: Jules Winnfield, Stephen, Nick Fury); 9 personajes son interpretados por más de un actor (ej. "Murphy Cooper" por Ellen Burstyn, Jessica Chastain y Mackenzie Foy)
- **Q26**: camino más corto entre "The Matrix" y "John Wick" = 2 saltos, vía Keanu Reeves
- **Q27**: Samuel L. Jackson tiene el mayor grado (21) en la red de coestrellas de películas
- **Q30**: ranking ponderado de recomendaciones para "The Matrix" (géneros×2 + actores×3 + director×5); "Terminator 2: Judgment Day" lidera con 6 géneros compartidos

---

## Paso 5: Consultas extra originales (Q31–Q35)

Las 5 consultas extra fueron definidas por el grupo y luego implementadas con Claude:

> "Resolvé estas 5 consultas extra que definimos nosotros: [descripción de cada una]"

### Q31 — Película más "hub"
**Motivación:** identificar qué película conecta indirectamente a más películas distintas a través
de actores compartidos, y cuántos actores sirven de puente. Aplica el concepto de centralidad de nodo al dominio de películas.

### Q32 — Ranking de compañías por rating ponderado
**Motivación:** un ranking simple por rating promedio favorece compañías con una sola obra buena.
El puntaje ponderado (suma de ratings) da más peso a compañías con muchas obras de calidad consistente.

### Q33 — Director más versátil
**Motivación:** medir versatilidad por cantidad de géneros distintos dirigidos, no por cantidad de películas.
Un director que hizo muchas películas del mismo género es menos versátil que uno con menos pero más diversas.

### Q34 — Géneros dominantes por década
**Motivación:** ver cómo evolucionaron los géneros a lo largo del tiempo, mostrando el top 5 por década
en lugar de un conteo total que aplana la dimensión temporal.

### Q35 — Cadena de colaboraciones entre dos actores
**Motivación:** dado un par de actores que nunca trabajaron juntos directamente, encontrar la cadena
más corta de colaboraciones que los conecta (variante del problema "Six Degrees of Kevin Bacon").
Los actores se eligen manualmente al inicio de la consulta.

> **Nota:** el dataset es pequeño (30 películas) y algunos actores quedan en subgrafos aislados.
> Para Q35 usar actores conectados, por ejemplo "Keanu Reeves" y "Orlando Bloom"
> (cadena: Keanu → The Matrix → Hugo Weaving → The Fellowship of the Ring → Orlando Bloom).

---

## Cómo ejecutar el proyecto

**Requisitos:** Docker instalado.

```bash
# 1. Levantar Neo4j
docker-compose up -d

# 2. Ejecutar los scripts en orden (reemplazar <container> con el nombre del contenedor)
docker exec -i <container> cypher-shell -u neo4j -p password123 < cypher/01_constraints.cypher
docker exec -i <container> cypher-shell -u neo4j -p password123 < cypher/02_load_nodes.cypher
docker exec -i <container> cypher-shell -u neo4j -p password123 < cypher/03_load_relationships.cypher

# 3. Abrir Neo4j Browser en http://localhost:7474 y ejecutar las consultas de cypher/04_consultas.cypher
```

El nombre del contenedor se obtiene con `docker ps`.

---

## Observaciones

- Dato sucio en el CSV original: `movie-014` tiene `title = "Q134773"` (debería ser "Forrest Gump"),
  y `company-025` / `company-039` tienen `name` igual a su wikidataId. Se dejó tal cual para no alterar
  los datos fuente; se documenta en el informe.
- Repositorio: `https://github.com/SantiBruschera/lab-5-neo4j`
