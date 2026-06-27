WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_production_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS distinct_production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_budget AS (
    SELECT
        mi.movie_id,
        CAST(regexp_replace(mi.info, '[^0-9.]', '') AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget' AND mi.info IS NOT NULL
)
SELECT
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(COALESCE(mcc.distinct_cast_count, 0)) AS total_cast_members,
    AVG(COALESCE(mcc.distinct_cast_count, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(mpc.distinct_production_company_count, 0)) AS total_production_companies,
    AVG(COALESCE(mpc.distinct_production_company_count, 0)) AS avg_production_companies_per_movie,
    SUM(COALESCE(mb.budget, 0)) AS total_budget,
    AVG(COALESCE(mb.budget, 0)) AS avg_budget_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
LEFT JOIN movie_production_companies mpc ON t.id = mpc.movie_id
LEFT JOIN movie_budget mb ON t.id = mb.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY total_cast_members DESC
LIMIT 10
