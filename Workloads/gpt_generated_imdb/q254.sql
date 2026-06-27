WITH actor_stats AS (
    SELECT
        name.id AS actor_id,
        name.name AS actor_name,
        name.gender,
        COUNT(DISTINCT title.id) AS distinct_movies,
        COUNT(DISTINCT char_name.id) AS distinct_characters,
        COUNT(*) AS total_appearances
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN title ON cast_info.movie_id = title.id
    LEFT JOIN char_name ON cast_info.person_role_id = char_name.id
    WHERE title.production_year >= 2000
    GROUP BY name.id, name.name, name.gender
)
SELECT
    actor_name,
    gender,
    distinct_movies,
    distinct_characters,
    total_appearances,
    CAST(distinct_characters AS double) / NULLIF(distinct_movies, 0) AS avg_characters_per_movie
FROM actor_stats
ORDER BY distinct_characters DESC, distinct_movies DESC
LIMIT 10
