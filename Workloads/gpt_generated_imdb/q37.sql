WITH keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count,
        COUNT(DISTINCT cn.country_code) AS company_country_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS title_kind,
    kc.keyword_count,
    cc.cast_count,
    comc.company_count,
    comc.company_type_count,
    comc.company_country_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts comc ON comc.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY kc.keyword_count DESC NULLS LAST
LIMIT 10
