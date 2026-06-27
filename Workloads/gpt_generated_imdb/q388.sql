WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
production_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind AS kind,
    COUNT(*) AS movie_count,
    COALESCE(SUM(cc.cast_count), 0) AS total_cast_members,
    COALESCE(SUM(kc.keyword_count), 0) AS total_keywords,
    COALESCE(SUM(pcc.prod_company_count), 0) AS total_production_companies,
    ROUND(COALESCE(SUM(cc.cast_count), 0) * 1.0 / COUNT(*), 2) AS avg_cast_per_movie,
    ROUND(COALESCE(SUM(kc.keyword_count), 0) * 1.0 / COUNT(*), 2) AS avg_keywords_per_movie,
    ROUND(COALESCE(SUM(pcc.prod_company_count), 0) * 1.0 / COUNT(*), 2) AS avg_production_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN production_company_counts pcc ON pcc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
