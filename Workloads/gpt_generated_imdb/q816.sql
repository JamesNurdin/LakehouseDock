WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
comp_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cp.company_count, 0) AS company_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(cc.cast_count, 0) + COALESCE(cp.company_count, 0) + COALESCE(kc.keyword_count, 0) AS total_entities
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
    ON t.id = cc.movie_id
LEFT JOIN comp_counts cp
    ON t.id = cp.movie_id
LEFT JOIN keyword_counts kc
    ON t.id = kc.movie_id
WHERE t.production_year >= 2000
ORDER BY total_entities DESC
LIMIT 10
