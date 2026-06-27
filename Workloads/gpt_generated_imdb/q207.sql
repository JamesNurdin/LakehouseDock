WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        cn.name AS character_name,
        kt.kind AS kind
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE kt.kind = 'movie'
)
SELECT
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    COUNT(DISTINCT character_name) AS distinct_characters,
    AVG(production_year) AS avg_production_year
FROM actor_movie_stats
GROUP BY actor_name
ORDER BY movie_count DESC
LIMIT 10
