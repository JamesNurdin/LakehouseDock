WITH movie_budgets AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS DOUBLE) AS budget
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS total_movies,
    SUM(COALESCE(mcc.company_count, 0)) AS total_companies,
    AVG(COALESCE(mcc.company_count, 0)) AS avg_companies_per_movie,
    AVG(mb.budget) AS avg_budget
FROM title t
LEFT JOIN movie_company_counts mcc
    ON mcc.movie_id = t.id
LEFT JOIN movie_budgets mb
    ON mb.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY avg_budget DESC NULLS LAST
