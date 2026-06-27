-- Top 10 production companies by number of movies, with average and median production year
WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        APPROX_PERCENTILE(t.production_year, 0.5) AS median_production_year
    FROM movie_companies mc
    JOIN title t               ON mc.movie_id = t.id
    JOIN company_name cn       ON mc.company_id = cn.id
    JOIN company_type ct       ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind
)
SELECT
    company_id,
    company_name,
    country_code,
    company_type,
    movie_count,
    avg_production_year,
    median_production_year
FROM company_movie_stats
ORDER BY movie_count DESC
LIMIT 10
