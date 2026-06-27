WITH actor_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT an.id) AS aka_name_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name, n.gender
)
SELECT
    actor_id,
    actor_name,
    gender,
    movie_count,
    character_count,
    aka_name_count,
    CAST(character_count AS double) / NULLIF(movie_count, 0) AS avg_characters_per_movie
FROM actor_stats
ORDER BY character_count DESC, movie_count DESC
LIMIT 10
