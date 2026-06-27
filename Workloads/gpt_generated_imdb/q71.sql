WITH actor_character_stats AS (
    SELECT
        n.id,
        n.name,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        COUNT(DISTINCT t.id) AS distinct_movies,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY n.id, n.name
)
SELECT
    id,
    name,
    distinct_characters,
    distinct_movies,
    first_year,
    last_year
FROM actor_character_stats
ORDER BY distinct_characters DESC, distinct_movies DESC, name
LIMIT 10
