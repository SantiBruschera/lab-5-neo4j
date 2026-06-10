// Carga de nodos de entidad a partir de los CSV (sin relaciones todavia)

// Movies
LOAD CSV WITH HEADERS FROM 'file:///csv/movies.csv' AS row
MERGE (m:Movie {id: row.id})
SET m.title = row.title,
    m.year = toIntegerOrNull(row.year),
    m.runtime = toIntegerOrNull(row.runtime),
    m.rating = toFloatOrNull(row.rating),
    m.ratingSource = row.ratingSource,
    m.description = row.description,
    m.wikidataId = row.wikidataId,
    m.imdbId = row.imdbId,
    m.sourceUrl = row.sourceUrl;

// Series
LOAD CSV WITH HEADERS FROM 'file:///csv/series.csv' AS row
MERGE (s:Series {id: row.id})
SET s.title = row.title,
    s.startYear = toIntegerOrNull(row.startYear),
    s.endYear = toIntegerOrNull(row.endYear),
    s.rating = toFloatOrNull(row.rating),
    s.ratingSource = row.ratingSource,
    s.description = row.description,
    s.tvmazeId = row.tvmazeId,
    s.sourceUrl = row.sourceUrl;

// Seasons (seriesId se modela luego como relacion)
LOAD CSV WITH HEADERS FROM 'file:///csv/seasons.csv' AS row
MERGE (se:Season {id: row.id})
SET se.seasonNumber = toIntegerOrNull(row.seasonNumber),
    se.year = toIntegerOrNull(row.year),
    se.tvmazeId = row.tvmazeId,
    se.sourceUrl = row.sourceUrl;

// Episodes (seriesId y seasonId se modelan luego como relaciones)
LOAD CSV WITH HEADERS FROM 'file:///csv/episodes.csv' AS row
MERGE (e:Episode {id: row.id})
SET e.title = row.title,
    e.seasonNumber = toIntegerOrNull(row.seasonNumber),
    e.episodeNumber = toIntegerOrNull(row.episodeNumber),
    e.year = toIntegerOrNull(row.year),
    e.runtime = toIntegerOrNull(row.runtime),
    e.rating = toFloatOrNull(row.rating),
    e.ratingSource = row.ratingSource,
    e.description = row.description,
    e.tvmazeId = row.tvmazeId,
    e.sourceUrl = row.sourceUrl;

// People
LOAD CSV WITH HEADERS FROM 'file:///csv/people.csv' AS row
MERGE (p:Person {id: row.id})
SET p.name = row.name,
    p.birthYear = toIntegerOrNull(row.birthYear),
    p.primaryProfession = split(row.primaryProfession, '; '),
    p.wikidataId = row.wikidataId,
    p.tvmazeId = row.tvmazeId,
    p.sourceUrl = row.sourceUrl;

// Characters
LOAD CSV WITH HEADERS FROM 'file:///csv/characters.csv' AS row
MERGE (c:Character {id: row.id})
SET c.name = row.name,
    c.description = row.description,
    c.wikidataId = row.wikidataId,
    c.tvmazeId = row.tvmazeId,
    c.sourceUrl = row.sourceUrl;

// Genres
LOAD CSV WITH HEADERS FROM 'file:///csv/genres.csv' AS row
MERGE (g:Genre {id: row.id})
SET g.name = row.name,
    g.wikidataId = row.wikidataId,
    g.sourceUrl = row.sourceUrl;

// Companies
LOAD CSV WITH HEADERS FROM 'file:///csv/companies.csv' AS row
MERGE (co:Company {id: row.id})
SET co.name = row.name,
    co.country = row.country,
    co.foundedYear = toIntegerOrNull(row.foundedYear),
    co.wikidataId = row.wikidataId,
    co.tvmazeId = row.tvmazeId,
    co.sourceUrl = row.sourceUrl;
