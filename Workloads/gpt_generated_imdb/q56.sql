WITH movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_cnt
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
),
movie_company_agg AS (
    SELECT
        mc.movie_id,
        mc.company_type_id,
        COUNT(*) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id, mc.company_type_id
)
SELECT
    kt.kind,
    mc.company_type_id,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    SUM(mc.company_cnt) AS total_company_entries,
    SUM(COALESCE(mi.info_cnt, 0)) / COUNT(DISTINCT t.id) AS avg_info_entries_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_company_agg mc ON mc.movie_id = t.id
LEFT JOIN movie_info_agg mi ON mi.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind, mc.company_type_id
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY kt.kind, mc.company_type_id
