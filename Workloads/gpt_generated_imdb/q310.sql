WITH companies_per_movie AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keywords_per_movie AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_per_movie AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_cnt
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cp.company_cnt, 0) AS company_cnt,
    COALESCE(kp.keyword_cnt, 0) AS keyword_cnt,
    COALESCE(ip.info_type_cnt, 0) AS info_type_cnt,
    ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY COALESCE(cp.company_cnt, 0) DESC) AS rank_in_kind
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN companies_per_movie cp
    ON cp.movie_id = t.id
LEFT JOIN keywords_per_movie kp
    ON kp.movie_id = t.id
LEFT JOIN info_per_movie ip
    ON ip.movie_id = t.id
WHERE t.production_year IS NOT NULL
ORDER BY kt.kind, rank_in_kind
LIMIT 100
