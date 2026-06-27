WITH mc_join AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        mc.company_type_id,
        t.production_year,
        ct.kind,
        cn.name,
        cn.country_code
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
        AND cn.country_code = 'US'
)
SELECT
    production_year,
    kind AS company_type,
    COUNT(DISTINCT movie_id) AS movie_count,
    COUNT(DISTINCT company_id) AS company_count,
    CAST(COUNT(*) AS double) / COUNT(DISTINCT movie_id) AS avg_companies_per_movie
FROM mc_join
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
