/*
   Analytical query: Top 10 actors (1990‑2020) who have portrayed the highest number of distinct characters in movies.
   The query joins the cast, person, character, title, and kind tables, filters for movies only and a production‑year window,
   then aggregates per actor.
*/
WITH actor_roles AS (
    SELECT
        n.id          AS person_id,
        n.name        AS actor_name,
        cn.id         AS character_id,
        t.production_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 1990 AND 2020
)
SELECT
    ar.person_id,
    ar.actor_name,
    COUNT(DISTINCT ar.character_id) AS distinct_characters,
    MIN(ar.production_year)       AS first_year,
    MAX(ar.production_year)       AS last_year,
    COUNT(*)                      AS total_roles
FROM actor_roles ar
GROUP BY ar.person_id, ar.actor_name
ORDER BY distinct_characters DESC, total_roles DESC
LIMIT 10
