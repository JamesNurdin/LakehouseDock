/* Top 10 companies by number of associated movies with production‑year statistics */
WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        COUNT(DISTINCT t.kind_id) AS distinct_kind_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS earliest_production_year,
        MAX(t.production_year) AS latest_production_year
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, cn.country_code
)
SELECT
    company_id,
    company_name,
    country_code,
    movie_count,
    distinct_kind_count,
    avg_production_year,
    earliest_production_year,
    latest_production_year,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
FROM company_movie_stats
ORDER BY movie_count DESC
LIMIT 10
