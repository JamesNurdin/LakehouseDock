WITH company_movie_stats AS (
    SELECT
        cn.id,
        cn.name,
        cn.country_code,
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_count,
        COUNT(*) AS total_company_appearances
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE cn.country_code = 'US'
    GROUP BY cn.id, cn.name, cn.country_code, mc.company_type_id
)
SELECT
    id,
    name,
    country_code,
    company_type_id,
    distinct_movie_count,
    total_company_appearances,
    ROUND(distinct_movie_count * 100.0 / total_company_appearances, 2) AS pct_distinct_movies
FROM company_movie_stats
ORDER BY total_company_appearances DESC
LIMIT 20
