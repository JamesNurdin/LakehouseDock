WITH role_counts AS (
    SELECT
        ci.person_id,
        cn.name AS role_name,
        COUNT(*) AS role_cnt
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
),

top_role AS (
    SELECT
        rc.person_id,
        rc.role_name,
        rc.role_cnt,
        ROW_NUMBER() OVER (PARTITION BY rc.person_id ORDER BY rc.role_cnt DESC, rc.role_name) AS rn
    FROM role_counts rc
),

person_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(*) AS total_movies,
        COUNT(DISTINCT kt.kind) AS distinct_kinds,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY n.id, n.name
)
SELECT
    ps.person_name,
    ps.total_movies,
    ps.distinct_kinds,
    ps.first_year,
    ps.last_year,
    tr.role_name AS most_frequent_role
FROM person_stats ps
LEFT JOIN (
    SELECT person_id, role_name
    FROM top_role
    WHERE rn = 1
) tr
    ON ps.person_id = tr.person_id
ORDER BY ps.total_movies DESC
LIMIT 10
