# Prompt de trabajo — Lab 05 Neo4j (Base de Datos III, ING0250, UM)

Este documento resume el contexto y los prompts/decisiones usados durante el desarrollo del lab con asistencia de IA (Claude Code), para acompañar la entrega.

## 1. Contexto y objetivo del lab

Según el enunciado (`ING0250 - Lab05 - Neo4j.pdf`), el objetivo es diseñar, modelar y consultar datos de cine/TV en Neo4j. Se entrega:

- Un template Docker con Neo4j vacío (`docker-compose.yml`, imagen `neo4j:5-community`, puertos 7474/7687, credenciales `neo4j`/`password123`).
- CSVs con datos de películas, series, episodios, personas, personajes, géneros y compañías (`data/csv/`), montados en `/var/lib/neo4j/import/csv` dentro del contenedor.

Hay que: (1) crear el proceso de carga de esos CSVs al grafo, (2) resolver 25 consultas predeterminadas, (3) resolver 5 consultas extra originales. Entregables: informe (modelado + proceso de inserción + 25 consultas con capturas + 5 extra con motivación), código fuente completo (incluyendo scripts de creación de estructuras), y video ≤10 min. Fecha límite: viernes 19/06/2026.

El archivo `queries/consultas.md` (provisto junto al template) reorganiza las 25 consultas del PDF más 5 extra en 30 consultas totales, agrupadas por dificultad (Fácil 1-10, Intermedio 11-20, Avanzado 21-30).

## 2. Dataset (`data/csv/`, 19 archivos)

**CSVs de entidades → nodos:**

| Archivo | Filas | Columnas |
|---|---|---|
| `movies.csv` | 30 | id, title, year, runtime, rating, ratingSource, description, wikidataId, imdbId, sourceUrl |
| `series.csv` | 10 | id, title, startYear, endYear, rating, ratingSource, description, tvmazeId, sourceUrl |
| `seasons.csv` | 30 | id, seriesId, seasonNumber, year, tvmazeId, sourceUrl |
| `episodes.csv` | 120 | id, seriesId, seasonId, title, seasonNumber, episodeNumber, year, runtime, rating, ratingSource, description, tvmazeId, sourceUrl |
| `people.csv` | 405 | id, name, birthYear, primaryProfession, wikidataId, tvmazeId, sourceUrl |
| `characters.csv` | 188 | id, name, description, wikidataId, tvmazeId, sourceUrl |
| `genres.csv` | 86 | id, name, wikidataId, sourceUrl |
| `companies.csv` | 45 | id, name, country, foundedYear, wikidataId, tvmazeId, sourceUrl |

**CSVs de cruce → relaciones:**

| Archivo | Columnas |
|---|---|
| `movie_cast.csv` | movieId, personId, characterId, roleName |
| `movie_directors.csv` / `movie_writers.csv` / `movie_producers.csv` | movieId, personId |
| `movie_genres.csv` | movieId, genreId |
| `episode_cast.csv` | episodeId, personId, characterId, roleName |
| `episode_directors.csv` / `episode_writers.csv` | episodeId, personId |
| `series_creators.csv` | seriesId, personId |
| `series_genres.csv` | seriesId, genreId |
| `production_companies.csv` | workType (Movie\|Series), workId, companyId |

## 3. Modelado del grafo

### Nodos (8 labels)

`Movie`, `Series`, `Season`, `Episode`, `Person`, `Character`, `Genre`, `Company` — uno por cada CSV de entidad, con constraint de unicidad por `id`.

Decisiones de tipado: `toIntegerOrNull()` / `toFloatOrNull()` para campos numéricos (maneja vacíos: 68 `Person.birthYear` y 8 `Company.foundedYear` quedan `null`); `Person.primaryProfession` se separa con `split(row.primaryProfession, '; ')` y queda como lista. `Episode` y `Season` no guardan `seriesId`/`seasonId` como propiedades porque se modelan como relaciones.

### Relaciones

| Relación | Origen CSV | Patrón |
|---|---|---|
| `HAS_SEASON` | seasons.csv (match por seriesId) | `(Series)-[:HAS_SEASON]->(Season)` |
| `HAS_EPISODE` | episodes.csv (match por seasonId) | `(Season)-[:HAS_EPISODE]->(Episode)` |
| `HAS_GENRE` | movie_genres.csv / series_genres.csv | `(Movie\|Series)-[:HAS_GENRE]->(Genre)` |
| `PRODUCED_BY` | production_companies.csv (según workType) | `(Movie\|Series)-[:PRODUCED_BY]->(Company)` |
| `DIRECTED` / `WROTE` / `PRODUCED` | movie_directors / movie_writers / movie_producers | `(Person)-[:REL]->(Movie)` |
| `CREATED` | series_creators.csv | `(Person)-[:CREATED]->(Series)` |
| `DIRECTED` / `WROTE` | episode_directors / episode_writers | `(Person)-[:REL]->(Episode)` |
| `ACTED_IN` | movie_cast / episode_cast | `(Person)-[:ACTED_IN]->(Movie\|Episode)` |
| `PLAYED {role}` | movie_cast / episode_cast | `(Person)-[:PLAYED]->(Character)` |
| `APPEARS_IN` | movie_cast / episode_cast | `(Character)-[:APPEARS_IN]->(Movie\|Episode)` |

El triángulo `Person-PLAYED->Character-APPEARS_IN->(Movie|Episode)` + `Person-ACTED_IN->(Movie|Episode)` permite resolver casos de doble personaje en una misma película (3 casos detectados, ej. `person-121` interpreta "self" y "Dick Cavett" en la misma película) y personajes interpretados por más de un actor (9 casos, ej. "Murphy Cooper" interpretada por 3 actrices en distintas edades).

## 4. Proceso de carga (ejecutado vía `docker exec -i <container> cypher-shell -u neo4j -p password123 < script.cypher`)

1. `cypher/01_constraints.cypher` — constraints `UNIQUE` por `id` en los 8 labels.
2. `cypher/02_load_nodes.cypher` — `LOAD CSV` + `MERGE` de los 8 nodos de entidad. Resultado: 914 nodos (Movie 30, Series 10, Season 30, Episode 120, Person 405, Character 188, Genre 86, Company 45).
3. `cypher/03_load_relationships.cypher` — `LOAD CSV` + `MATCH`/`MERGE` de las relaciones descritas arriba. Resultado: 2620 relaciones (`ACTED_IN` 769, `APPEARS_IN` 729, `WROTE` 205, `PLAYED` 199, `HAS_GENRE` 237, `DIRECTED` 163, `PRODUCED_BY` 83, `PRODUCED` 67, `HAS_EPISODE` 120, `HAS_SEASON` 30, `CREATED` 18).

## 5. Consultas resueltas (`cypher/04_consultas.cypher`)

Las 30 consultas de `queries/consultas.md` (25 obligatorias del PDF + 5 extra), escritas en Cypher y validadas contra el grafo cargado. Algunos resultados destacados:

- **#13/#25**: 14 actores interpretan más de un personaje (ej. Samuel L. Jackson: Jules Winnfield, Stephen, Nick Fury); 9 personajes interpretados por más de un actor (ej. "Murphy Cooper" por Ellen Burstyn, Jessica Chastain y Mackenzie Foy).
- **#26**: camino más corto entre "The Matrix" y "John Wick" = 2 saltos, vía Keanu Reeves.
- **#27**: Samuel L. Jackson tiene el mayor grado (21) en la red de coestrellas de películas.
- **#30**: ranking ponderado de recomendaciones para "The Matrix" (géneros×2 + actores×3 + director×5); "Terminator 2: Judgment Day" lidera con 6 géneros compartidos.

## 6. Observaciones / pendientes

- Dato sucio detectado en el CSV original: `movie-014` tiene `title = "Q134773"` (es "Forrest Gump"), y `company-025` / `company-039` tienen `name` igual a su wikidataId. Pendiente decidir si se corrige en los CSV o se documenta tal cual en el informe.
- Falta: capturas de las 30 consultas en Neo4j Browser, redacción del informe y grabación del video de presentación.

## 7. Repositorio

Código fuente y scripts disponibles en: `https://github.com/SantiBruschera/lab-5-neo4j`
