WITH
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ak.id) AS alt_name_count
    FROM cast_info ci
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.id AS movie_id,
    t.title,
    kt.kind,
    t.production_year,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cc.alt_name_count, 0) AS alt_name_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(comc.company_count, 0) AS company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts comc ON comc.movie_id = t.id
ORDER BY cast_count DESC
LIMIT 20
