-- Top production company types by number of movies and average cast size per year (2000‑2020)
WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.production_year
)
SELECT
    ct.kind AS company_type,
    mc.production_year,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mc.cast_count) AS avg_cast_per_movie
FROM movie_cast_counts mc
JOIN movie_companies mco
    ON mco.movie_id = mc.movie_id
JOIN company_type ct
    ON mco.company_type_id = ct.id
GROUP BY ct.kind, mc.production_year
ORDER BY movie_count DESC
LIMIT 20
