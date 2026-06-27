WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(compc.production_company_count, 0) AS production_company_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
LEFT JOIN movie_company_counts compc ON t.id = compc.movie_id
LEFT JOIN movie_keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year >= 2010
ORDER BY cast_count DESC
LIMIT 20
