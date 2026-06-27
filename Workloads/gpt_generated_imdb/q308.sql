WITH actor_role_counts AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        cn.name AS role_name,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id, n.name, cn.name
),
actor_top_role AS (
    SELECT
        actor_id,
        actor_name,
        role_name,
        role_count,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY role_count DESC) AS rn
    FROM actor_role_counts
),
actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year BETWEEN 1990 AND 2020
    GROUP BY n.id, n.name
)
SELECT
    ams.actor_name,
    ams.movie_count,
    ams.first_year,
    ams.last_year,
    atr.role_name AS most_frequent_role,
    atr.role_count AS role_appearances
FROM actor_movie_stats ams
LEFT JOIN (
    SELECT actor_id, role_name, role_count
    FROM actor_top_role
    WHERE rn = 1
) atr ON ams.actor_id = atr.actor_id
ORDER BY ams.movie_count DESC
LIMIT 10
