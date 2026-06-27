WITH cast_counts AS (
    SELECT
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_count
    FROM cast_info
    GROUP BY cast_info.movie_id
),
keyword_counts AS (
    SELECT
        movie_keyword.movie_id,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_keyword.movie_id
),
production_companies AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(kc.keyword_count) AS avg_keywords_per_movie,
    COUNT(DISTINCT pc.company_id) FILTER (WHERE pc.company_type_kind = 'production') AS distinct_production_companies
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN production_companies pc ON t.id = pc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year, kt.kind
