WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY n.id, n.name
),
actor_role_counts AS (
    SELECT
        ci.person_id AS actor_id,
        cn.id AS role_id,
        cn.name AS role_name,
        COUNT(*) AS role_appearances
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY ci.person_id, cn.id, cn.name
),
actor_top_role AS (
    SELECT
        arc.actor_id,
        arc.role_name,
        arc.role_appearances,
        ROW_NUMBER() OVER (PARTITION BY arc.actor_id ORDER BY arc.role_appearances DESC) AS rn
    FROM actor_role_counts arc
)
SELECT
    a.actor_name,
    a.movie_count,
    a.first_year,
    a.last_year,
    tr.role_name AS most_frequent_role,
    tr.role_appearances AS role_appearances
FROM actor_movie_stats a
LEFT JOIN actor_top_role tr
    ON a.actor_id = tr.actor_id AND tr.rn = 1
ORDER BY a.movie_count DESC
LIMIT 10
