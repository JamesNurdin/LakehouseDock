WITH actor_metrics AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year,
        COUNT(DISTINCT an.id) AS aka_name_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    LEFT JOIN aka_name an ON an.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT *
FROM actor_metrics
ORDER BY character_count DESC, movie_count DESC
LIMIT 10
