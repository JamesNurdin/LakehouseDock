WITH actor_year_stats AS (
    SELECT
        t.production_year AS production_year,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, n.name
),
ranked_actors AS (
    SELECT
        production_year,
        actor_name,
        movie_count,
        character_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM actor_year_stats
)
SELECT
    production_year,
    actor_name,
    movie_count,
    character_count
FROM ranked_actors
WHERE rn <= 3
ORDER BY production_year, movie_count DESC
