WITH cast_counts AS (
    SELECT
        ci.movie_id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id AS movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id AS movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0)      AS cast_count,
    COALESCE(kc.keyword_count, 0)   AS keyword_count,
    COALESCE(compc.company_count, 0) AS company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC, keyword_count DESC, company_count DESC
LIMIT 10
