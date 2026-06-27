WITH actor_movie_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT t.id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year IS NOT NULL
    GROUP BY n.id, n.name
),
actor_top_role AS (
    SELECT
        ci.person_id,
        cn.name AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(*) DESC) AS rn
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
)
SELECT
    amc.person_name,
    amc.movie_count,
    amc.first_year,
    amc.last_year,
    atr.role_name AS most_common_role
FROM actor_movie_counts amc
JOIN actor_top_role atr
    ON amc.person_id = atr.person_id
WHERE atr.rn = 1
ORDER BY amc.movie_count DESC
LIMIT 10
