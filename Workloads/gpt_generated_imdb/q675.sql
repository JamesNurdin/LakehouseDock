WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS min_production_year,
        MAX(t.production_year) AS max_production_year
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind
)
SELECT
    company_id,
    company_name,
    country_code,
    company_type,
    movie_count,
    avg_production_year,
    min_production_year,
    max_production_year,
    RANK() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS rank_within_type
FROM company_movie_stats
WHERE movie_count >= 10
ORDER BY company_type, rank_within_type
LIMIT 50
