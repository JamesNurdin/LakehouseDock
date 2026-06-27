WITH company_movie_stats AS (
    SELECT
        mc.company_id,
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS min_production_year,
        MAX(t.production_year) AS max_production_year
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY mc.company_id, mc.company_type_id
)
SELECT
    company_id,
    company_type_id,
    movie_count,
    avg_production_year,
    min_production_year,
    max_production_year,
    RANK() OVER (ORDER BY movie_count DESC) AS movie_count_rank
FROM company_movie_stats
ORDER BY movie_count DESC
LIMIT 20
