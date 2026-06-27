WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ci.person_role_id) AS character_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
budget_agg AS (
    SELECT
        mi.movie_id,
        SUM(CAST(mi.info AS double)) AS total_budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    t.kind_id,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.character_count, 0) AS character_count,
    COALESCE(ba.total_budget, 0) AS total_budget
FROM title t
LEFT JOIN cast_agg ca ON t.id = ca.movie_id
LEFT JOIN budget_agg ba ON t.id = ba.movie_id
WHERE t.production_year IS NOT NULL
ORDER BY t.production_year DESC, total_budget DESC
LIMIT 20
