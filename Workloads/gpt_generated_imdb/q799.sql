/*
   Analytical query: for each person (actor/actress) compute the number of movies they appear in,
   count of distinct alternate names (aka_name), earliest and latest production year of their movies,
   and rank them by movie count.
   Joins follow the allowed rules only.
*/
WITH actor_stats AS (
    SELECT
        n.id AS name_id,
        n.name AS primary_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ak.id) AS aka_name_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN title t ON ci.movie_id = t.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    name_id,
    primary_name,
    gender,
    movie_count,
    aka_name_count,
    first_year,
    last_year,
    RANK() OVER (ORDER BY movie_count DESC) AS movie_rank
FROM actor_stats
WHERE movie_count > 0
ORDER BY movie_count DESC
LIMIT 50
