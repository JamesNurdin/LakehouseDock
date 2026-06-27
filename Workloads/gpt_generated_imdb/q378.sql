WITH actor_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS role_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY n.id, n.name, n.gender
)
SELECT
    actor_id,
    actor_name,
    gender,
    movie_count,
    role_count,
    avg_production_year
FROM actor_stats
ORDER BY movie_count DESC, role_count DESC
LIMIT 10
