WITH us_production AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        t.production_year,
        cn.country_code,
        ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE t.production_year BETWEEN 2000 AND 2020
        AND cn.country_code = 'US'
        AND ct.kind = 'production'
)
SELECT
    us_production.production_year,
    COUNT(DISTINCT us_production.movie_id) AS movie_count,
    COUNT(DISTINCT us_production.company_id) AS distinct_company_count,
    CAST(COUNT(DISTINCT us_production.movie_id) AS double) / COUNT(DISTINCT us_production.company_id) AS movies_per_company
FROM us_production
GROUP BY us_production.production_year
HAVING COUNT(DISTINCT us_production.movie_id) > 5
ORDER BY movie_count DESC
LIMIT 10
