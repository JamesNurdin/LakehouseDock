WITH movie_base AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind AS kind_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
      AND kt.kind = 'movie'
),
movie_company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS us_production_company_cnt
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
      AND cn.country_code = 'US'
    GROUP BY mc.movie_id
),
movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_cnt
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    mb.production_year,
    mb.kind_name,
    COUNT(DISTINCT mb.id) AS total_movies,
    SUM(COALESCE(mca.us_production_company_cnt, 0)) AS total_us_production_companies,
    SUM(COALESCE(mia.info_cnt, 0)) AS total_info_entries,
    AVG(COALESCE(mia.info_cnt, 0)) AS avg_info_per_movie
FROM movie_base mb
LEFT JOIN movie_company_agg mca ON mca.movie_id = mb.id
LEFT JOIN movie_info_agg mia ON mia.movie_id = mb.id
GROUP BY mb.production_year, mb.kind_name
ORDER BY total_movies DESC
LIMIT 20
