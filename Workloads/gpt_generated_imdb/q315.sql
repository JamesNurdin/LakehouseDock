WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
budget_info AS (
    SELECT mi.movie_id,
           MAX(TRY_CAST(mi.info AS double)) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_cnt) AS avg_cast_per_movie,
    AVG(compc.comp_cnt) AS avg_companies_per_movie,
    SUM(budget_info.budget) AS total_budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN budget_info ON budget_info.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
