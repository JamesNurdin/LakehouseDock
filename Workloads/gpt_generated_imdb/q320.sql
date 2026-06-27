WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_production_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(*) AS movie_count,
    AVG(cast_counts.cast_count) AS avg_cast_per_movie,
    AVG(pc_counts.prod_company_count) AS avg_prod_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts cast_counts ON t.id = cast_counts.movie_id
LEFT JOIN movie_production_companies pc_counts ON t.id = pc_counts.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year, kt.kind
