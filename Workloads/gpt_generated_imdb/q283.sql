WITH movie_base AS (
    SELECT t.id AS movie_id,
           t.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.production_year
),
movie_genres AS (
    SELECT mi.movie_id,
           it.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
),
movie_runtimes AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT mg.genre,
       COUNT(DISTINCT mb.movie_id) AS movie_count,
       AVG(mb.production_year) AS avg_production_year,
       AVG(mb.cast_count) AS avg_cast_per_movie,
       AVG(mr.runtime_minutes) AS avg_runtime_minutes
FROM movie_genres mg
JOIN movie_base mb ON mb.movie_id = mg.movie_id
LEFT JOIN movie_runtimes mr ON mr.movie_id = mb.movie_id
GROUP BY mg.genre
ORDER BY movie_count DESC
LIMIT 10
