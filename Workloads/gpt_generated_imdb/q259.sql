WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(*) AS movie_cnt,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_cnt,
    AVG(COALESCE(compc.comp_cnt, 0)) AS avg_company_cnt,
    AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keyword_cnt
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
    ON t.id = cc.movie_id
LEFT JOIN company_counts compc
    ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc
    ON t.id = kc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY movie_cnt DESC
LIMIT 20
