// Consultas del Lab 05 - Neo4j
// Numeracion segun queries/consultas.md (1-30: Facil, Intermedio, Avanzado)

// ===================== FACIL =====================

// 1. Listar las peliculas con anio de estreno, duracion y URL de origen.
MATCH (m:Movie)
RETURN m.title AS pelicula, m.year AS anioEstreno, m.runtime AS duracionMin, m.sourceUrl AS url
ORDER BY pelicula;

// 2. Listar las series con anio de inicio, anio de finalizacion, rating de TVmaze y URL de origen.
MATCH (s:Series)
RETURN s.title AS serie, s.startYear AS anioInicio, s.endYear AS anioFin, s.rating AS ratingTVmaze, s.sourceUrl AS url
ORDER BY serie;

// 3. Contar cuantas peliculas o series estan conectadas a cada genero.
MATCH (g:Genre)<-[:HAS_GENRE]-(work)
RETURN g.name AS genero,
       count(work) AS total,
       count(CASE WHEN work:Movie THEN 1 END) AS peliculas,
       count(CASE WHEN work:Series THEN 1 END) AS series
ORDER BY total DESC, genero;

// 4. Mostrar el reparto y los nombres de los personajes de la pelicula "The Matrix".
MATCH (p:Person)-[:ACTED_IN]->(m:Movie {title: "The Matrix"})
MATCH (p)-[played:PLAYED]->(c:Character)-[:APPEARS_IN]->(m)
RETURN p.name AS actor, c.name AS personaje, played.role AS rolAcreditado
ORDER BY actor;

// 5. Listar los episodios muestreados de la temporada 1 de "Game of Thrones".
MATCH (s:Series {title: "Game of Thrones"})-[:HAS_SEASON]->(se:Season {seasonNumber: 1})-[:HAS_EPISODE]->(e:Episode)
RETURN e.episodeNumber AS episodio, e.title AS titulo, e.year AS anio, e.runtime AS duracionMin, e.rating AS rating
ORDER BY episodio;

// 6. Mostrar las companias o cadenas conectadas a cada pelicula o serie.
MATCH (work)-[:PRODUCED_BY]->(co:Company)
WHERE work:Movie OR work:Series
RETURN labels(work)[0] AS tipo, work.title AS obra, collect(co.name) AS companias
ORDER BY tipo, obra;

// 7. Listar las peliculas junto con sus directores. (extra)
MATCH (m:Movie)
OPTIONAL MATCH (p:Person)-[:DIRECTED]->(m)
RETURN m.title AS pelicula, collect(p.name) AS directores
ORDER BY pelicula;

// 8. Listar las series junto con sus creadores. (extra)
MATCH (s:Series)
OPTIONAL MATCH (p:Person)-[:CREATED]->(s)
RETURN s.title AS serie, collect(p.name) AS creadores
ORDER BY serie;

// 9. Mostrar los episodios muestreados con mejor rating.
MATCH (s:Series)-[:HAS_SEASON]->(se:Season)-[:HAS_EPISODE]->(e:Episode)
RETURN s.title AS serie, se.seasonNumber AS temporada, e.episodeNumber AS episodio, e.title AS titulo, e.rating AS rating
ORDER BY e.rating DESC, serie, temporada, episodio
LIMIT 10;

// 10. Contar los estrenos de peliculas por decada. (extra)
MATCH (m:Movie)
WITH (m.year / 10) * 10 AS decada
RETURN decada, count(*) AS estrenos
ORDER BY decada;

// ===================== INTERMEDIO =====================

// 11. Calcular la duracion promedio de las peliculas por genero.
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre)
RETURN g.name AS genero, round(avg(m.runtime), 1) AS duracionPromedioMin, count(m) AS peliculas
ORDER BY duracionPromedioMin DESC;

// 12. Encontrar personas acreditadas en mas de un tipo de rol.
MATCH (p:Person)-[r]->(work)
WHERE type(r) IN ['DIRECTED', 'WROTE', 'PRODUCED', 'ACTED_IN', 'CREATED']
WITH p, collect(DISTINCT type(r)) AS tiposDeRol
WHERE size(tiposDeRol) > 1
RETURN p.name AS persona, tiposDeRol, size(tiposDeRol) AS cantidadTipos
ORDER BY cantidadTipos DESC, persona;

// 13. Encontrar interpretes que hayan interpretado mas de un personaje.
MATCH (p:Person)-[:PLAYED]->(c:Character)
WITH p, collect(DISTINCT c.name) AS personajes
WHERE size(personajes) > 1
RETURN p.name AS actor, personajes, size(personajes) AS cantidad
ORDER BY cantidad DESC, actor;

// 14. Encontrar los personajes que aparecen en mas obras muestreadas.
MATCH (c:Character)-[:APPEARS_IN]->(work)
RETURN c.name AS personaje, count(work) AS apariciones
ORDER BY apariciones DESC, personaje
LIMIT 10;

// 15. Encontrar las companias o cadenas conectadas a mas obras. (extra)
MATCH (co:Company)<-[:PRODUCED_BY]-(work)
RETURN co.name AS compania, count(work) AS obras
ORDER BY obras DESC, compania
LIMIT 10;

// 16. Encontrar colaboraciones entre directores y guionistas en peliculas.
MATCH (d:Person)-[:DIRECTED]->(m:Movie)<-[:WROTE]-(w:Person)
WHERE d <> w
RETURN d.name AS director, w.name AS guionista, collect(m.title) AS peliculas, count(m) AS cantidad
ORDER BY cantidad DESC, director, guionista;

// 17. Encontrar personas que actuaron tanto en peliculas como en episodios muestreados de series.
MATCH (p:Person)
WHERE EXISTS { (p)-[:ACTED_IN]->(:Movie) } AND EXISTS { (p)-[:ACTED_IN]->(:Episode) }
OPTIONAL MATCH (p)-[:ACTED_IN]->(m:Movie)
OPTIONAL MATCH (p)-[:ACTED_IN]->(e:Episode)
RETURN p.name AS persona, count(DISTINCT m) AS peliculas, count(DISTINCT e) AS episodiosMuestreados
ORDER BY persona;

// 18. Calcular estadisticas de rating de episodios por serie y temporada.
MATCH (s:Series)-[:HAS_SEASON]->(se:Season)-[:HAS_EPISODE]->(e:Episode)
RETURN s.title AS serie, se.seasonNumber AS temporada,
       round(avg(e.rating), 2) AS ratingPromedio,
       min(e.rating) AS ratingMin,
       max(e.rating) AS ratingMax,
       count(e) AS episodios
ORDER BY serie, temporada;

// 19. Encontrar nombres de generos de peliculas y series que se solapan por texto.
MATCH (mg:Genre)<-[:HAS_GENRE]-(:Movie)
WITH DISTINCT mg
MATCH (sg:Genre)<-[:HAS_GENRE]-(:Series)
WHERE toLower(mg.name) CONTAINS toLower(sg.name)
RETURN DISTINCT sg.name AS generoSerie, mg.name AS generoPelicula
ORDER BY generoSerie, generoPelicula;

// 20. Encontrar pares de coestrellas de peliculas y las peliculas que comparten.
MATCH (a:Person)-[:ACTED_IN]->(m:Movie)<-[:ACTED_IN]-(b:Person)
WHERE a.id < b.id
WITH a, b, collect(m.title) AS peliculasCompartidas
RETURN a.name AS actor1, b.name AS actor2, peliculasCompartidas, size(peliculasCompartidas) AS cantidad
ORDER BY cantidad DESC, actor1, actor2
LIMIT 20;

// ===================== AVANZADO =====================

// 21. Encontrar personas conectadas a una misma compania a traves de creditos de actuacion o equipo tecnico.
MATCH (a:Person)-[:ACTED_IN|DIRECTED|WROTE|PRODUCED|CREATED]->(workA)-[:PRODUCED_BY]->(co:Company)
MATCH (b:Person)-[:ACTED_IN|DIRECTED|WROTE|PRODUCED|CREATED]->(workB)-[:PRODUCED_BY]->(co)
WHERE a.id < b.id
WITH co, a, b, count(DISTINCT workA) AS obrasA, count(DISTINCT workB) AS obrasB
RETURN co.name AS compania, a.name AS persona1, b.name AS persona2, obrasA + obrasB AS conexiones
ORDER BY conexiones DESC, compania, persona1, persona2
LIMIT 15;

// 22. Recomendar peliculas que compartan generos con "The Matrix". (extra)
MATCH (matrix:Movie {title: "The Matrix"})-[:HAS_GENRE]->(g:Genre)<-[:HAS_GENRE]-(rec:Movie)
WHERE rec <> matrix
WITH rec, collect(g.name) AS generosCompartidos
RETURN rec.title AS pelicula, generosCompartidos, size(generosCompartidos) AS cantidad
ORDER BY cantidad DESC, pelicula
LIMIT 10;

// 23. Recomendar peliculas que compartan actores con "The Matrix".
MATCH (matrix:Movie {title: "The Matrix"})<-[:ACTED_IN]-(p:Person)-[:ACTED_IN]->(rec:Movie)
WHERE rec <> matrix
WITH rec, collect(p.name) AS actoresCompartidos
RETURN rec.title AS pelicula, actoresCompartidos, size(actoresCompartidos) AS cantidad
ORDER BY cantidad DESC, pelicula;

// 24. Encontrar nodos del grafo a una distancia maxima de dos saltos desde "The Matrix".
MATCH (matrix:Movie {title: "The Matrix"})
MATCH p = (matrix)-[*1..2]-(n)
WHERE n <> matrix
WITH n, min(length(p)) AS distancia
RETURN labels(n)[0] AS tipo, coalesce(n.title, n.name) AS nombre, distancia
ORDER BY distancia, tipo, nombre;

// 25. Encontrar personajes interpretados por mas de una persona.
MATCH (c:Character)<-[:PLAYED]-(p:Person)
WITH c, collect(DISTINCT p.name) AS actores
WHERE size(actores) > 1
RETURN c.name AS personaje, actores, size(actores) AS cantidad
ORDER BY cantidad DESC, personaje;

// 26. Encontrar el camino mas corto del grafo entre "The Matrix" y "John Wick".
MATCH (a:Movie {title: "The Matrix"}), (b:Movie {title: "John Wick"})
MATCH p = shortestPath((a)-[*]-(b))
RETURN [n IN nodes(p) | coalesce(n.title, n.name)] AS nodos,
       [r IN relationships(p) | type(r)] AS relaciones,
       length(p) AS longitud;

// 27. Ordenar actores segun su grado dentro de la red de coestrellas de peliculas.
MATCH (a:Person)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(b:Person)
WHERE a <> b
WITH a, count(DISTINCT b) AS grado
RETURN a.name AS actor, grado
ORDER BY grado DESC, actor
LIMIT 15;

// 28. Encontrar personas que conectan series de TV con peliculas mediante creditos de actuacion.
MATCH (ser:Series)-[:HAS_SEASON]->(:Season)-[:HAS_EPISODE]->(e:Episode)<-[:ACTED_IN]-(p:Person)-[:ACTED_IN]->(m:Movie)
WITH p, collect(DISTINCT ser.title) AS series, collect(DISTINCT m.title) AS peliculas
RETURN p.name AS persona, series, peliculas
ORDER BY persona;

// 29. Comparar el solapamiento de generos entre peliculas y series.
MATCH (sg:Genre)<-[:HAS_GENRE]-(s:Series)
WITH sg, count(DISTINCT s) AS serieCount
OPTIONAL MATCH (mg:Genre)<-[:HAS_GENRE]-(m:Movie)
WHERE toLower(mg.name) CONTAINS toLower(sg.name)
RETURN sg.name AS conceptoGenero, serieCount AS series, count(DISTINCT m) AS peliculasRelacionadas
ORDER BY conceptoGenero;

// 30. Crear un puntaje ponderado de recomendacion para peliculas relacionadas con "The Matrix".
MATCH (matrix:Movie {title: "The Matrix"})
MATCH (rec:Movie) WHERE rec <> matrix
OPTIONAL MATCH (matrix)-[:HAS_GENRE]->(g:Genre)<-[:HAS_GENRE]-(rec)
WITH matrix, rec, count(DISTINCT g) AS generosCompartidos
OPTIONAL MATCH (matrix)<-[:ACTED_IN]-(actor:Person)-[:ACTED_IN]->(rec)
WITH matrix, rec, generosCompartidos, count(DISTINCT actor) AS actoresCompartidos
OPTIONAL MATCH (matrix)<-[:DIRECTED]-(dir:Person)-[:DIRECTED]->(rec)
WITH rec, generosCompartidos, actoresCompartidos, count(DISTINCT dir) AS directorCompartido
WHERE generosCompartidos > 0 OR actoresCompartidos > 0 OR directorCompartido > 0
RETURN rec.title AS pelicula,
       generosCompartidos,
       actoresCompartidos,
       directorCompartido,
       (generosCompartidos * 2 + actoresCompartidos * 3 + directorCompartido * 5) AS puntaje
ORDER BY puntaje DESC, pelicula
LIMIT 10;

// 31. Encontrar la pelicula mas "hub": la que conecta indirectamente a mas peliculas distintas
// a traves de actores compartidos, junto con cuantos actores sirven de puente.
MATCH (m:Movie)<-[:ACTED_IN]-(p:Person)-[:ACTED_IN]->(other:Movie)
WHERE m <> other
WITH m,
     count(DISTINCT other) AS peliculasConectadas,
     count(DISTINCT p) AS actoresPuente,
     collect(DISTINCT other.title) AS conexiones
RETURN m.title AS pelicula, peliculasConectadas, actoresPuente, conexiones
ORDER BY peliculasConectadas DESC, actoresPuente DESC
LIMIT 10;

// 32. Rankear companias productoras por rating promedio ponderado por cantidad de obras,
// para que una compania con muchas obras buenas pese mas que una con una sola.
MATCH (co:Company)<-[:PRODUCED_BY]-(work)
WHERE (work:Movie OR work:Series)
  AND work.rating IS NOT NULL
WITH co,
     count(DISTINCT work) AS cantidadObras,
     avg(work.rating) AS ratingPromedio,
     sum(work.rating) AS puntajePonderado
RETURN co.name AS compania,
       cantidadObras,
       round(ratingPromedio, 2) AS ratingPromedio,
       round(puntajePonderado, 2) AS puntajePonderado
ORDER BY puntajePonderado DESC,
         ratingPromedio DESC,
         cantidadObras DESC,
         compania
LIMIT 15;

// 33. Encontrar el director mas versatil segun la cantidad de generos distintos en los que dirigio peliculas.
MATCH (d:Person)-[:DIRECTED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WITH d,
     count(DISTINCT g) AS cantidadGeneros,
     count(DISTINCT m) AS peliculasDirigidas,
     collect(DISTINCT g.name) AS generosDirigidos
RETURN d.name AS director,
       cantidadGeneros,
       peliculasDirigidas,
       generosDirigidos
ORDER BY cantidadGeneros DESC,
         peliculasDirigidas DESC,
         director
LIMIT 1;

// 34. Ver que generos dominaron cada decada analizando la cantidad de estrenos por genero agrupados en intervalos de 10 anios.
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE m.year IS NOT NULL
WITH toInteger(floor(m.year / 10.0) * 10) AS decada,
     g.name AS genero,
     count(DISTINCT m) AS estrenos
ORDER BY decada, estrenos DESC, genero
WITH decada,
     collect({genero: genero, estrenos: estrenos}) AS rankingGeneros
UNWIND range(0, size(rankingGeneros) - 1) AS indice
WITH decada,
     indice + 1 AS posicion,
     rankingGeneros[indice] AS item
WHERE posicion <= 5
RETURN toString(decada) + 's' AS decada,
       posicion,
       item.genero AS genero,
       item.estrenos AS estrenos
ORDER BY decada, posicion;

// 35. Elegir manualmente dos actores que nunca trabajaron juntos directamente
// y encontrar la cadena mas corta de colaboraciones que los conecta.
// Cambiar actor1 y actor2 por los nombres deseados.
WITH "Keanu Reeves" AS actor1, "Orlando Bloom" AS actor2
MATCH (a:Person {name: actor1})
WITH a, actor1, actor2
MATCH (b:Person {name: actor2})
WHERE a.id <> b.id
  AND NOT EXISTS {
    MATCH (a)-[:ACTED_IN]->(obra)<-[:ACTED_IN]-(b)
    WHERE obra:Movie OR obra:Episode
  }
MATCH path = shortestPath((a)-[:ACTED_IN*..20]-(b))
WHERE all(n IN nodes(path) WHERE n:Person OR n:Movie OR n:Episode)
RETURN actor1,
       actor2,
       [n IN nodes(path) |
          CASE
            WHEN n:Person THEN 'Actor: ' + n.name
            WHEN n:Movie THEN 'Pelicula: ' + n.title
            WHEN n:Episode THEN 'Episodio: ' + n.title
          END
       ] AS cadenaColaboraciones,
       length(path) / 2 AS saltosEntreActores,
       length(path) AS longitudGrafo;
       