WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender AS gender,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS distinct_role_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name, n.gender
)
SELECT
    actor_id,
    actor_name,
    gender,
    movie_count,
    distinct_role_count,
    first_year,
    last_year
FROM actor_movie_stats
ORDER BY movie_count DESC
LIMIT 10
