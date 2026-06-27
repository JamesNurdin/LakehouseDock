WITH actor_stats AS (
    SELECT
        name.name AS actor_name,
        COUNT(DISTINCT title.id) AS movie_count,
        COUNT(DISTINCT char_name.id) AS character_count,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN title ON cast_info.movie_id = title.id
    LEFT JOIN char_name ON cast_info.person_role_id = char_name.id
    LEFT JOIN movie_keyword ON movie_keyword.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY name.name
)
SELECT actor_name,
       movie_count,
       character_count,
       keyword_count
FROM actor_stats
ORDER BY movie_count DESC
LIMIT 10
