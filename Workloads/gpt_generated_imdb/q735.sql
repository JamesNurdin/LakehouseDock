WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
production_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS distinct_keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(cc.distinct_cast_count, 0) AS cast_count,
    COALESCE(pc.production_company_count, 0) AS production_company_count,
    COALESCE(kc.distinct_keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN production_company_counts pc ON t.id = pc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year >= 2000
  AND kt.kind = 'movie'
ORDER BY cast_count DESC
LIMIT 10
