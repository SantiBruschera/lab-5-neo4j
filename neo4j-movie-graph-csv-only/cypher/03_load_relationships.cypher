// Series -> Season (match por seriesId)
LOAD CSV WITH HEADERS FROM 'file:///csv/seasons.csv' AS row
MATCH (s:Series {id: row.seriesId})
MATCH (se:Season {id: row.id})
MERGE (s)-[:HAS_SEASON]->(se);

// Season -> Episode (match por seasonId)
LOAD CSV WITH HEADERS FROM 'file:///csv/episodes.csv' AS row
MATCH (se:Season {id: row.seasonId})
MATCH (e:Episode {id: row.id})
MERGE (se)-[:HAS_EPISODE]->(e);



// Movie -> Genre
LOAD CSV WITH HEADERS FROM 'file:///csv/movie_genres.csv' AS row
MATCH (m:Movie {id: row.movieId})
MATCH (g:Genre {id: row.genreId})
MERGE (m)-[:HAS_GENRE]->(g);

// Series -> Genre
LOAD CSV WITH HEADERS FROM 'file:///csv/series_genres.csv' AS row
MATCH (s:Series {id: row.seriesId})
MATCH (g:Genre {id: row.genreId})
MERGE (s)-[:HAS_GENRE]->(g);



// Movie -> Company
LOAD CSV WITH HEADERS FROM 'file:///csv/production_companies.csv' AS row
WITH row WHERE row.workType = 'Movie'
MATCH (m:Movie {id: row.workId})
MATCH (co:Company {id: row.companyId})
MERGE (m)-[:PRODUCED_BY]->(co);

// Series -> Company
LOAD CSV WITH HEADERS FROM 'file:///csv/production_companies.csv' AS row
WITH row WHERE row.workType = 'Series'
MATCH (s:Series {id: row.workId})
MATCH (co:Company {id: row.companyId})
MERGE (s)-[:PRODUCED_BY]->(co);



// Person -> Movie (DIRECTED / WROTE / PRODUCED)
LOAD CSV WITH HEADERS FROM 'file:///csv/movie_directors.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (m:Movie {id: row.movieId})
MERGE (p)-[:DIRECTED]->(m);

LOAD CSV WITH HEADERS FROM 'file:///csv/movie_writers.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (m:Movie {id: row.movieId})
MERGE (p)-[:WROTE]->(m);

LOAD CSV WITH HEADERS FROM 'file:///csv/movie_producers.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (m:Movie {id: row.movieId})
MERGE (p)-[:PRODUCED]->(m);

// Person -> Series (CREATED)
LOAD CSV WITH HEADERS FROM 'file:///csv/series_creators.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (s:Series {id: row.seriesId})
MERGE (p)-[:CREATED]->(s);

// Person -> Episode (DIRECTED / WROTE)
LOAD CSV WITH HEADERS FROM 'file:///csv/episode_directors.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (e:Episode {id: row.episodeId})
MERGE (p)-[:DIRECTED]->(e);

LOAD CSV WITH HEADERS FROM 'file:///csv/episode_writers.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (e:Episode {id: row.episodeId})
MERGE (p)-[:WROTE]->(e);



// Movie cast
LOAD CSV WITH HEADERS FROM 'file:///csv/movie_cast.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (m:Movie {id: row.movieId})
MATCH (c:Character {id: row.characterId})
MERGE (p)-[:ACTED_IN]->(m)
MERGE (p)-[pl:PLAYED]->(c)
  SET pl.role = row.roleName
MERGE (c)-[:APPEARS_IN]->(m);

// Episode cast
LOAD CSV WITH HEADERS FROM 'file:///csv/episode_cast.csv' AS row
MATCH (p:Person {id: row.personId})
MATCH (e:Episode {id: row.episodeId})
MATCH (c:Character {id: row.characterId})
MERGE (p)-[:ACTED_IN]->(e)
MERGE (p)-[pl:PLAYED]->(c)
  SET pl.role = row.roleName
MERGE (c)-[:APPEARS_IN]->(e);
