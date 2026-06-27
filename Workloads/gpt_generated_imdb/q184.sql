/*
  Analytical query: Top 10 actors (by number of movies released from 2000 onward) 
  showing the count of distinct movies, distinct keywords associated with those movies, 
  the number of alternate names (aka_name) they have, and the average production year of 
  their movies.  All joins respect the declared join rules.
*/
WITH actor_movies AS (
    SELECT
        n.id        AS person_id,
        n.name      AS person_name,
        n.gender    AS gender,
        t.id        AS movie_id,
        t.production_year,
        mk.keyword_id,
        ak.name     AS aka_name
    FROM name n
    JOIN cast_info ci      ON ci.person_id = n.id
    JOIN title t           ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN aka_name ak      ON ak.person_id = n.id
    WHERE t.production_year >= 2000
)
SELECT
    person_id,
    person_name,
    gender,
    COUNT(DISTINCT movie_id)   AS movie_count,
    COUNT(DISTINCT keyword_id) AS keyword_count,
    COUNT(DISTINCT aka_name)   AS aka_name_count,
    AVG(production_year)       AS avg_production_year
FROM actor_movies
GROUP BY person_id, person_name, gender
ORDER BY movie_count DESC
LIMIT 10
