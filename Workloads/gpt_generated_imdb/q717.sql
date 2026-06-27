WITH movie_genres AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        mi.info AS genre,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
      AND it.info = 'genres'
      AND t.production_year IS NOT NULL
)
SELECT
    mg.production_year,
    mg.genre,
    COUNT(DISTINCT mg.movie_id) AS movie_count,
    COUNT(DISTINCT n.id) AS actor_count,
    CAST(COUNT(DISTINCT n.id) AS DOUBLE) / COUNT(DISTINCT mg.movie_id) AS avg_actors_per_movie
FROM movie_genres mg
JOIN cast_info ci ON ci.movie_id = mg.movie_id
JOIN name n ON n.id = ci.person_id
GROUP BY mg.production_year, mg.genre
ORDER BY movie_count DESC, actor_count DESC
LIMIT 100
