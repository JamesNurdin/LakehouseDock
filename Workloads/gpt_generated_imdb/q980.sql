WITH keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_stats AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_cnt,
        AVG(length(mi.info)) AS avg_info_len
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_company_distinct AS (
    SELECT DISTINCT
        mc.movie_id,
        mc.company_type_id
    FROM movie_companies mc
)
SELECT
    t.production_year,
    mc.company_type_id,
    COUNT(DISTINCT t.id) AS movie_cnt,
    SUM(COALESCE(kc.keyword_cnt, 0)) AS total_keywords,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    SUM(COALESCE(is_s.info_cnt, 0)) AS total_info_entries,
    AVG(COALESCE(is_s.avg_info_len, 0)) AS avg_info_length
FROM title t
JOIN movie_company_distinct mc
    ON mc.movie_id = t.id
LEFT JOIN keyword_counts kc
    ON kc.movie_id = t.id
LEFT JOIN info_stats is_s
    ON is_s.movie_id = t.id
WHERE t.kind_id = 1
GROUP BY t.production_year, mc.company_type_id
ORDER BY t.production_year DESC, mc.company_type_id
