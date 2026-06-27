WITH company_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_cnt,
        COUNT(*) AS total_appearances,
        SUM(CASE WHEN mc.company_type_id = 1 THEN 1 ELSE 0 END) AS production_cnt,
        SUM(CASE WHEN mc.company_type_id = 2 THEN 1 ELSE 0 END) AS distribution_cnt,
        SUM(CASE WHEN mc.company_type_id = 3 THEN 1 ELSE 0 END) AS special_effects_cnt
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE cn.country_code = 'US'
    GROUP BY cn.id, cn.name, cn.country_code
)
SELECT
    company_id,
    company_name,
    country_code,
    distinct_movie_cnt,
    total_appearances,
    production_cnt,
    distribution_cnt,
    special_effects_cnt,
    (production_cnt * 100.0 / total_appearances) AS pct_production,
    (distribution_cnt * 100.0 / total_appearances) AS pct_distribution,
    (special_effects_cnt * 100.0 / total_appearances) AS pct_special_effects,
    ROW_NUMBER() OVER (ORDER BY distinct_movie_cnt DESC) AS rank_by_movies
FROM company_stats
WHERE total_appearances >= 10
ORDER BY distinct_movie_cnt DESC
LIMIT 50
