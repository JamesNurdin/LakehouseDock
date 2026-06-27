WITH actor_stats AS (
    SELECT
        name.id AS actor_id,
        name.name AS actor_name,
        name.gender,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count,
        COUNT(DISTINCT char_name.id) AS distinct_role_count,
        MIN(title.production_year) AS first_year,
        MAX(title.production_year) AS last_year
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN title ON cast_info.movie_id = title.id
    LEFT JOIN char_name ON cast_info.person_role_id = char_name.id
    GROUP BY name.id, name.name, name.gender
)
SELECT
    actor_id,
    actor_name,
    gender,
    movie_count,
    distinct_role_count,
    first_year,
    last_year,
    RANK() OVER (ORDER BY movie_count DESC) AS movie_rank
FROM actor_stats
ORDER BY movie_count DESC
LIMIT 10
