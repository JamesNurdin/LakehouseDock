WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_budgets AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
)
SELECT
    md.production_year,
    md.kind,
    COUNT(*) AS movie_count,
    AVG(md.budget) AS avg_budget,
    AVG(md.cast_cnt) AS avg_cast_size,
    AVG(md.budget) / NULLIF(AVG(md.cast_cnt), 0) AS avg_budget_per_cast
FROM (
    SELECT
        d.movie_id,
        d.title,
        d.production_year,
        d.kind,
        mb.budget,
        cc.cast_cnt
    FROM movie_details d
    LEFT JOIN movie_budgets mb ON mb.movie_id = d.movie_id
    LEFT JOIN cast_counts cc ON cc.movie_id = d.movie_id
) md
GROUP BY md.production_year, md.kind
HAVING COUNT(*) >= 5
ORDER BY md.production_year DESC, avg_budget_per_cast DESC
LIMIT 20
