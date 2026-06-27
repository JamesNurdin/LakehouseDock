WITH actor_movies AS (
    SELECT
        name.id AS actor_id,
        name.name AS actor_name,
        title.id AS movie_id,
        title.production_year
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN title ON cast_info.movie_id = title.id
    JOIN kind_type ON title.kind_id = kind_type.id
    WHERE kind_type.kind = 'movie'
      AND title.production_year BETWEEN 2000 AND 2020
)
SELECT
    actor_id,
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    MIN(production_year) AS first_year,
    MAX(production_year) AS last_year
FROM actor_movies
GROUP BY actor_id, actor_name
ORDER BY movie_count DESC, actor_name
LIMIT 10
