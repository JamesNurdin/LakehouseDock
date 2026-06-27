WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name,
        mc.company_id,
        mc.company_type_id,
        mi.info_type_id,
        mi.info
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT
    actor_id,
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    MIN(production_year) AS first_year,
    MAX(production_year) AS last_year,
    COUNT(DISTINCT company_id) AS distinct_companies,
    COUNT(DISTINCT character_name) AS distinct_characters
FROM actor_movie_stats
GROUP BY actor_id, actor_name
HAVING COUNT(DISTINCT movie_id) >= 5
ORDER BY movie_count DESC
LIMIT 20
