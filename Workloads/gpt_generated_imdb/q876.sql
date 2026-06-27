/*
  Analytical query: for each actor (person) who has appeared in at least 5 feature‑film titles,
  compute the number of distinct movies, the average IMDb rating (if present), the count of
  distinct keywords associated with those movies, the number of different company types the
  movies were linked to, and the span of production years. Results are ordered by the total
  number of movies and limited to the top 20 actors.
*/
WITH actor_movie_info AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        mi.info AS rating,
        k.keyword,
        ct.kind AS company_type
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
        AND it.info = 'rating'
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE kt.kind = 'movie'
)
SELECT
    person_id,
    actor_name,
    COUNT(DISTINCT movie_id)                         AS total_movies,
    AVG(CAST(rating AS double))                      AS avg_rating,
    COUNT(DISTINCT keyword)                          AS distinct_keyword_count,
    COUNT(DISTINCT company_type)                     AS distinct_company_type_count,
    MIN(production_year)                             AS first_year,
    MAX(production_year)                             AS last_year
FROM actor_movie_info
GROUP BY person_id, actor_name
HAVING COUNT(DISTINCT movie_id) >= 5
ORDER BY total_movies DESC
LIMIT 20
